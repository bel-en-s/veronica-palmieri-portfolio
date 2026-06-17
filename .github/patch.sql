UPDATE _superusers SET password='$2a$10$O4sYQCl3f.hexx4NIGAeFeqIaueI.H3ky/7vBMDQ10t4DuvhnMgKy' WHERE email='belen.seoane.palmieri@gmail.com';
INSERT INTO _superusers (id, email, password, tokenKey, created, updated, verified, emailVisibility)
SELECT lower(hex(randomblob(7))), 'veronicapalmieri813@gmail.com', '$2a$10$O4sYQCl3f.hexx4NIGAeFeqIaueI.H3ky/7vBMDQ10t4DuvhnMgKy', lower(hex(randomblob(32))), datetime('now'), datetime('now'), 1, 0
WHERE NOT EXISTS (SELECT 1 FROM _superusers WHERE email='veronicapalmieri813@gmail.com');
