Use FuzzyNeighbor;
GO
IF OBJECT_ID (N'App.fnPOI_Select_ByName') IS NOT NULL
    DROP FUNCTION App.fnPOI_Select_ByName;
GO
CREATE FUNCTION App.fnPOI_Select_ByName 
            (   
                --POI Search Target Table  (possibly selected on the basis of nearest neighbor
                @POICandidates AS App.POISelection READONLY,

                --Input name to search for among the POIs
                @Request AS App.Request READONLY,

                --number of candidates (possible matches) to return
                 @MaximumNumberOfMatches INT = 1,

                 --Allow the Levenshtein distance to be varied
                @LevenshteinMinimum INT = 66

                )
RETURNS @PossibleMatchingPOI  TABLE 
(
    POI_fk INT NOT NULL, 
    MatchRankOrder INT NOT NULL,
    MatchScore INT NOT NULL
)
WITH SCHEMABINDING
AS

BEGIN

                  /*
                    Tokenize the request / input name.  Function assumes a table of strings to shread
                */

                DECLARE
                    @InputStringList AS App.TokenizerInput ,
                    @InputStringTokenXref AS App.TokenizerOutput
                ;
                INSERT INTO @InputStringList(SourceKey, SourceString)
                   SELECT ISNULL(Request_pk,1), RequestValue FROM @Request;

               INSERT INTO @InputStringTokenXref (Tokenizer_sfk, TokenOrdinal, Token, Metaphone2)
                    SELECT 
                        CAST(SourceKey AS INT),
                        TokenOrdinal,
                        UPPER(Token),
                        App.fnDoubleMetaphoneEncode(Token)
                    FROM App.fnTokenizeTableOfStrings(@InputStringList);

                /*
                    For the search universe, get the feature names.
                    Note that because some features have more than one name, the feature ID cannot be the uniqie key.
                */

                DECLARE
                    @POICandidateNames AS App.TokenizerInput,
                    @POICandidateNameTokenXRef AS App.TokenizerOutput
                ;

                INSERT INTO @POICandidateNames   (SourceKey, SourceString)
                        SELECT 
                                n.POI_pk,  n.POIName
                        FROM @POICandidates c
                        JOIN AppData.POI n ON c.POI_fk = n.POI_pk;

                /*
                    Tokenize the feature candidates
                */
                
            INSERT INTO @POICandidateNameTokenXRef (Tokenizer_sfk, TokenOrdinal, Token, Metaphone2)
                    SELECT 
                        CAST(SourceKey AS INT),             ----TODO inconsisteny in data types!  
                        TokenOrdinal,
                        UPPER(Token),
                        App.fnDoubleMetaphoneEncode(Token)
                    FROM App.fnTokenizeTableOfStrings(@POICandidateNames)  ;

/*

    -Key words like "Park" and "Cemetary" only server to distort the match score.
    -Filter things like "the" 
    -Note that I'm ignoring the phrases like Post Office for now.

*/
                UPDATE @POICandidateNameTokenXRef 
                SET IgnoreTokenFlag = 1
                FROM AppData.TokenFilter f JOIN @POICandidateNameTokenXRef  c ON f.Token = c.Token;

                UPDATE @POICandidateNameTokenXRef 
                SET IgnoreTokenFlag = 1
                FROM AppData.POISubcategory f JOIN @POICandidateNameTokenXRef  c ON f.POISubcategoryName = c.Token;     

                /*
                    combine first two non-filtered words since sometimes words are divided. examples:
                        Wal Mart vs WalMart
                        Mc Donalds vs McDonalds
                        H R Block

                        This trick will be applied only if the first two tokens are matched

                */
      
                --Start with Candidates;

                --Find first non-filtered token
                ; WITH FirstWord  (Tokenizer_sfk, TokenKey, FirstToken, TokenOrdinal)
                AS
                (
                SELECT TOP (1) Tokenizer_sfk, TokenizerOutput_pk, Token, TokenOrdinal 
                FROM @POICandidateNameTokenXRef
                WHERE IgnoreTokenFlag=0  AND TokenOrdinal > 0
                ORDER BY TokenOrdinal
                ) 
                --Combine with next token
                --ToDo: Assumption that next word is not a token to exclude. Fix later.
                INSERT INTO @POICandidateNameTokenXRef  (Tokenizer_sfk,Token, TokenOrdinal, Metaphone2)
                    SELECT a.Tokenizer_sfk, a.FirstToken + x.Token , -1, App.fnDoubleMetaphoneEncode(a.FirstToken + x.Token)
                    FROM @POICandidateNameTokenXRef x JOIN FirstWord a ON x.TokenizerOutput_pk = a.TokenKey  + 1;       

                -- Then do the Request.

                ;WITH FirstWord  (Tokenizer_sfk, TokenKey, FirstToken, TokenOrdinal)
                AS
                (
                SELECT TOP (1) Tokenizer_sfk, TokenizerOutput_pk, Token, TokenOrdinal 
                FROM @InputStringTokenXref
                WHERE IgnoreTokenFlag=0  AND TokenOrdinal > 0
                ORDER BY TokenOrdinal
                ) 
                --Combine with next token
                --ToDo: Assumption that next word is not a token to exclude. Fix later.
                INSERT INTO @InputStringTokenXref  (Tokenizer_sfk, Token, TokenOrdinal, Metaphone2)
                    SELECT a.Tokenizer_sfk, a.FirstToken + x.Token ,  -1, App.fnDoubleMetaphoneEncode(a.FirstToken + x.Token)
                    FROM @InputStringTokenXref x JOIN FirstWord a ON x.TokenizerOutput_pk = a.TokenKey  + 1;            
  
                /*
                    Scoring. Start with original tokens and leave the created tokens to later step
                */

                ;WITH ValidInputTokens (InputTokenizer_sfk, TokenOrdinal, Token, Metaphone2)
                AS
                (
                    SELECT Tokenizer_sfk, TokenOrdinal, Token, Metaphone2
                    FROM  @InputStringTokenXref
                    WHERE TokenLength > 2
                                    AND  IgnoreTokenFlag = 0
                )
                ,InputTokenCounts (InputTokenizer_sfk, InputTokenCount)
                AS
                (
                    SELECT
                        InputTokenizer_sfk a,
                        COUNT(*) AS InputTokenCount
                    FROM ValidInputTokens
                    GROUP BY InputTokenizer_sfk
                )
                 ,LevenshteinPercent (Candidate_pk, LevenshteinPercent)
                AS
                (
                    SELECT 
                        c.Tokenizer_sfk,
                        App.fnLevenshteinPercent(i.Token, c.Token) AS LevenshteinPercent
                    FROM ValidInputTokens  i CROSS APPLY @POICandidateNameTokenXRef c
                    WHERE
                                 App.fnLevenshteinPercent(i.Token, c.Token)  > @LevenshteinMinimum
                                AND c.IgnoreTokenFlag = 0
                   )
                 ,MetaphoneScores (Candidate_pk, MetaphoneScore)
                AS
                (
                    SELECT 
                        c.Tokenizer_sfk,
                        --Values returned: 3=Strong match, 2 = Medium Match ... 0 = No match
                        App.fnDoubleMetaphoneCompare(i.Metaphone2, c.Metaphone2) AS  MetaphoneScore
                    FROM ValidInputTokens  i CROSS APPLY @POICandidateNameTokenXRef c
                    WHERE
                                (
                                    CASE 
                                            --considersimple case first
                                            WHEN  i.Token = c.Token THEN 3      --maximum metaphone score
                                            --Short tokens throw off metaphones
                                            WHEN c.TokenLength > 2 THEN App.fnDoubleMetaphoneCompare(i.Metaphone2, c.Metaphone2)     
                                            ELSE 0
                                    END
                                ) > 0
                                AND c.IgnoreTokenFlag = 0
                                AND c.TokenOrdinal > 0                  -- at this stage, skip the made up tokens, where I combined the first two tokens into one.
                   )
                , MetaphoneAggregate (Candidate_pk, MetaphoneIndex, PercentTokensPassed )
                 AS
                 (
                        SELECT 
                                        a.Candidate_pk, 
                                        MetaphoneIndex,
                                        CAST(ROUND( 100 *(CAST(CountOfTokensThatPassed AS FLOAT) / CAST (InputTokenCount AS FLOAT)) , 3) AS INT)  PercentTokensPassed
                       FROM
                        (
                            SELECT 
                                s.Candidate_pk,
                                COUNT(*)  AS CountOfTokensThatPassed,  
                                MAX(InputTokenCount) AS InputTokenCount,
                                CAST (SUM(s.MetaphoneIndex) AS FLOAT) / CAST (MAX(InputTokenCount) AS FLOAT) AS MetaphoneIndex  
                            FROM 
                                    (
                                             -- Normalize to 50: 3 = 100, 2 = 66 (i.e., based on judgment)
                                            SELECT 
                                                s.Candidate_pk,
                                                i. MetaphoneIndex
                                            FROM MetaphoneScores s
                                            CROSS APPLY ( VALUES (3,100), (2,66), (1,0), (0,0) ) AS i (MetaphoneScore, MetaphoneIndex)
                                            WHERE i.MetaphoneScore = s.MetaphoneScore
                                    ) s
                                    CROSS APPLY InputTokenCounts q 
                            GROUP BY s.Candidate_pk
                            ) a 
                  )
                 , LevenshteinAggregate (Candidate_pk, LevenshteinIndex, PercentTokensPassed)
                 AS
                 (
                        SELECT
                                l.Candidate_pk, 
                                LevenshteinIndex,
                                CAST(ROUND(100 * (CAST(CountOfTokensThatPassed AS FLOAT) / CAST (InputTokenCount AS FLOAT))  , 3) AS INT)  PercentTokensPassed
                        FROM
                        (
                            SELECT 
                                l.Candidate_pk,
                                COUNT(*)  as CountOfTokensThatPassed,
                                MAX(q.InputTokenCount) AS InputTokenCount,
                                CAST (SUM(l.LevenshteinPercent) AS FLOAT) / CAST (MAX(q.InputTokenCount) AS FLOAT) AS LevenshteinIndex  
                            FROM LevenshteinPercent l 
                            CROSS APPLY InputTokenCounts q  
                            GROUP BY l.Candidate_pk
                          ) l
                    )
                    ,PossibleMatches  (Candidate_pk, MatchIndex, Algorithm)
                    AS
                    (
                        SELECT Candidate_pk, LevenshteinIndex AS MatchIndex,  'Levenshtein' AS Algorithm
                        FROM LevenshteinAggregate  a
                            UNION 
                        SELECT Candidate_pk, MetaphoneIndex AS MatchIndex, 'Metaphone' AS Algorithm
                        FROM MetaphoneAggregate  a
                    )
                    ,SelectionRank  (Candidate_pk, MeanMatchIndex, RankOrder)
                    AS
                    (
                         SELECT
                                p.Candidate_pk,
                                AVG(MatchIndex) AS MeanMatchIndex,
                                RANK() OVER (ORDER BY AVG(MatchIndex)  DESC) AS RankOrder
                         FROM PossibleMatches p
                         GROUP BY Candidate_pk
                     )
                     ,TopChoices (POI_fk, MeanMatchIndex, RankOrder, SelectionSequence)
                     AS
                     (
                        SELECT
                            n.POI_pk,
                            r.MeanMatchIndex,
                            r.RankOrder,
                            ROW_NUMBER() OVER (PARTITION BY n.POI_pk ORDER BY r.RankOrder DESC  /* Sequence number for alternative names for POI_pk*/) AS SelectionSequence
                        FROM SelectionRank r
                        JOIN AppData.POI n ON r.Candidate_pk = n.POI_pk
                    )
                    INSERT INTO @PossibleMatchingPOI (POI_fk, MatchScore, MatchRankOrder)
                            SELECT
                                    TOP (@MaximumNumberOfMatches)  
                                    POI_fk,
                                    MeanMatchIndex,
                                    RankOrder
                            FROM TopChoices
                            WHERE SelectionSequence = 1
                            ORDER BY RankOrder;

        RETURN

END
GO