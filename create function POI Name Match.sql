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
                 @MaximumNumberOfMatches INT = 1

                )
RETURNS @PossibleMatchingPOI  TABLE 
(
    POI_fk INT NOT NULL, 
    MatchRankOrder INT NOT NULL,
    MatchScore INT NOT NULL
)
--WITH SCHEMABINDING
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
                        Tokenizer_sfk,
                        TokenOrdinal,
                        Token,
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
                        JOIN AppData.POI n ON c.POI_fk = n.POI_pk

                /*
                    Tokenize the feature candidates
                */
                
            INSERT INTO @POICandidateNameTokenXRef (Tokenizer_sfk, TokenOrdinal, Token, Metaphone2)
                    SELECT 
                        CAST(SourceKey AS INT),             ----TODO inconsisteny in data types!  
                        TokenOrdinal,
                        Token,
                        App.fnDoubleMetaphoneEncode(Token)
                    FROM App.fnTokenizeTableOfStrings(@POICandidateNames)  ;

/*
    These two steps are unqiue to the Gazetteer data set. There are more efficeint ways to handle them.

    -Key words like "Park" and "Cemetary" only server to distort the match score.
    -Note that I'm ignoring the phrases like Post Office for now.


*/
                UPDATE @POICandidateNameTokenXRef 
                SET IgnoreTokenFlag = 1
                WHERE TOKEN = '(Historical)';

/*                
                UPDATE @POICandidateNameTokenXRef 
                SET IgnoreTokenFlag = 1
                FROM AppData.FeatureClassFilter c JOIN @POICandidateNameTokenXRef  f
                ON f.TOKEN = c.FeatureClassName;
*/


                /*
                    Scoring. 
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
                                App.fnLevenshteinPercent(i.Token, c.Token) > 66
                                AND c.TokenLength > 2
                                          AND c.IgnoreTokenFlag = 0
                   )
                 ,MetaphoneScores (Candidate_pk, MetaphoneScore)
                AS
                (
                    SELECT 
                        c.Tokenizer_sfk,
                        App.fnDoubleMetaphoneCompare(i.Metaphone2, c.Metaphone2) AS  MetaphoneScore
                    FROM ValidInputTokens  i CROSS APPLY @POICandidateNameTokenXRef c
                    WHERE
                                App.fnDoubleMetaphoneCompare(i.Metaphone2, c.Metaphone2)  > 0
                                AND c.TokenLength > 2
                                AND c.IgnoreTokenFlag = 0
                   )
                , MetaphoneAggregate (Candidate_pk, MetaphoneIndex, PercentTokensPassed )
                 AS
                 (
                        SELECT  
                                        a.Candidate_pk, MetaphoneIndex,
                                        CAST(ROUND( CAST(CountOfTokensThatPassed AS FLOAT) / CAST (InputTokenCount AS FLOAT)  , 2) AS INT)  PercentTokensPassed
                        FROM
                        (
                            SELECT 
                                s.Candidate_pk,
                                COUNT(*)  as CountOfTokensThatPassed,
                                CAST(ROUND(CAST(AVG(s.MetaphoneScore) AS FLOAT) * 100,3) AS INT) AS MetaphoneIndex     --normalize to 100
                            FROM MetaphoneScores s
                            GROUP BY s.Candidate_pk
                            ) a 
                            CROSS APPLY InputTokenCounts q 
                  )
                 , LevenshteinAggregate  (Candidate_pk, LevenshteinIndex, PercentTokensPassed)
                 AS
                 (
                        SELECT
                                a.Candidate_pk, LevenshteinIndex,
                                CAST(ROUND(CAST(CountOfTokensThatPassed AS FLOAT) / CAST (InputTokenCount AS FLOAT)  , 2) AS INT)  PercentTokensPassed
                        FROM
                        (
                            SELECT 
                                s.Candidate_pk,
                                COUNT(*)  as CountOfTokensThatPassed,
                                AVG(s.LevenshteinPercent) AS LevenshteinIndex       --its a percentage, so sort of equivalent to a normalized value
                            FROM LevenshteinPercent s 
                            GROUP BY s.Candidate_pk
                          ) a 
                            CROSS APPLY InputTokenCounts q  
                    )
                    ,PossibleMatches  (Candidate_pk, MatchIndex)
                    AS
                    (
                        SELECT Candidate_pk, LevenshteinIndex AS MatchIndex
                        FROM LevenshteinAggregate  a
                            UNION 
                        SELECT Candidate_pk, MetaphoneIndex AS MatchIndex
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