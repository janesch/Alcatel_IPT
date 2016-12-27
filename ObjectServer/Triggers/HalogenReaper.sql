CREATE  OR REPLACE  TRIGGER HalogenDecommReaper
GROUP Failover
DEBUG FALSE
ENABLED TRUE
PRIORITY 20
 COMMENT 'Chris Janes	20120215	Original'
EVERY 1  HOURS
BEGIN
for each row expire in alerts.status where expire.Class = 50000 and expire.InServiceStatus = 'De-commissioned'
        begin
                update alerts.status via expire.Identifier set Severity = 0;
        end;
END;