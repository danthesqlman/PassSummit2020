--Run second 

BEGIN TRAN

UPDATE ##Music
                             SET Digits = N'555-1212'
                             WHERE MusicID = 1





--Run Forth
							 UPDATE ##People
                             SET Digits = N'555-9999'
                             WHERE PersonId = 1





ROLLBACK TRAN