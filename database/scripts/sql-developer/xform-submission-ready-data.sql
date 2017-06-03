SET TRIMSPOOL ON
SET ECHO OFF
SET VERIFY OFF
SPOOL H:\xform_gwells_land_district.csv

SELECT /*csv*/  
  TRIM(WELLS.WELLS_LEGAL_LAND_DIST_CODES.LEGAL_LAND_DISTRICT_CODE) AS CODE,
  TRIM(WELLS.WELLS_LEGAL_LAND_DIST_CODES.LEGAL_LAND_DISTRICT_NAME) AS NAME,
  WELLS.WELLS_LEGAL_LAND_DIST_CODES.SORT_ORDER,
  SYS_GUID() AS LAND_DISTRICT_GUID
FROM WELLS.WELLS_LEGAL_LAND_DIST_CODES
ORDER BY trim(LEGAL_LAND_DISTRICT_NAME)
/
SPOOL OFF



SET ECHO OFF
SET VERIFY OFF
SPOOL H:\xform_gwells_well.csv

SELECT /*csv*/ 
  to_char(WELLS.WELLS_WELLS.WHEN_CREATED,'YYYY-MM-DD HH24:MI:SS') || '.000000+00' AS created,
  to_char(WELLS.WELLS_WELLS.WHEN_UPDATED,'YYYY-MM-DD HH24:MI:SS') || '.000000+00' AS modified,
  NVL2(WELLS.WELLS_OWNERS.GIVEN_NAME,WELLS.WELLS_OWNERS.GIVEN_NAME || ' ', NULL) || WELLS.WELLS_OWNERS.SURNAME AS owner_full_name,
   CASE
   WHEN WELLS.WELLS_OWNERS.ADDRESS_LINE IS NULL THEN
     NVL2(WELLS.WELLS_OWNERS.STREET_NUMBER,WELLS.WELLS_OWNERS.STREET_NUMBER || ' ', NULL) || 
     NVL2(WELLS.WELLS_OWNERS.STREET_NAME,WELLS.WELLS_OWNERS.STREET_NAME || ' ', NULL)
   ELSE
      WELLS.WELLS_OWNERS.STREET_NAME
   END AS owner_mailing_address,  
  WELLS.WELLS_OWNERS.CITY AS owner_city,
  WELLS.WELLS_OWNERS.POSTAL_CODE AS owner_postal_code,
  WELLS.WELLS_WELLS.SITE_STREET AS STREET_ADDRESS,
  WELLS.WELLS_WELLS.SITE_AREA AS city,
  WELLS.WELLS_WELLS.LOT_NUMBER AS legal_lot,
  WELLS.WELLS_WELLS.LEGAL_PLAN,
  WELLS.WELLS_WELLS.LEGAL_DISTRICT_LOT,
  WELLS.WELLS_WELLS.LEGAL_BLOCK,
  WELLS.WELLS_WELLS.LEGAL_SECTION,
  WELLS.WELLS_WELLS.LEGAL_TOWNSHIP,
  WELLS.WELLS_WELLS.LEGAL_RANGE,
  WELLS.WELLS_WELLS.PID AS legal_pid,
  WELLS.WELLS_WELLS.WELL_LOCATION AS well_location_description,
  WELLS.WELLS_WELLS.WELL_IDENTIFICATION_PLATE_NO AS identification_plate_number,
  WELLS.WELLS_WELLS.WELL_TAG_NUMBER,
  WELLS.WELLS_WELLS.DIAMETER,
  WELLS.WELLS_WELLS.TOTAL_DEPTH_DRILLED,
  WELLS.WELLS_WELLS.DEPTH_WELL_DRILLED AS FINISHED_WELL_DEPTH,
  WELLS.WELLS_WELLS.YIELD_VALUE AS WELL_YIELD,
  SYS_GUID() AS WELL_GUID,
  WELLS.WELLS_WELLS.WELL_USE_CODE,
  WELLS.WELLS_WELLS.LEGAL_LAND_DISTRICT_CODE,
  CASE
    WHEN WELLS.WELLS_OWNERS.PROVINCE_STATE_CODE = 'BC' THEN 'f46b70b647d411e7a91992ebcb67fe33'
    WHEN WELLS.WELLS_OWNERS.PROVINCE_STATE_CODE = 'AB' THEN 'f46b742647d411e7a91992ebcb67fe33'
    WHEN WELLS.WELLS_OWNERS.PROVINCE_STATE_CODE = 'WASH_STATE' THEN 'f46b77b447d411e7a91992ebcb67fe33'
    ELSE  /* 'OTHER' */ 'f46b7b1a47d411e7a91992ebcb67fe33'
  END AS province_state_guid,
  WELLS.WELLS_WELLS.CLASS_OF_WELL_CODE,
  WELLS.WELLS_WELLS.SUBCLASS_OF_WELL_CODE,
  CASE
    WHEN WELLS.WELLS_WELLS.YIELD_UNIT_CODE = 'GPM'  THEN 'c4634ef447c311e7a91992ebcb67fe33'
    WHEN WELLS.WELLS_WELLS.YIELD_UNIT_CODE = 'IGM'  THEN 'c4634ff847c311e7a91992ebcb67fe33'
    WHEN WELLS.WELLS_WELLS.YIELD_UNIT_CODE = 'DRY'  THEN 'c46347b047c311e7a91992ebcb67fe33'
    WHEN WELLS.WELLS_WELLS.YIELD_UNIT_CODE = 'LPS'  THEN 'c46350c047c311e7a91992ebcb67fe33'
    WHEN WELLS.WELLS_WELLS.YIELD_UNIT_CODE = 'USGM' THEN 'c463525047c311e7a91992ebcb67fe33'
    WHEN WELLS.WELLS_WELLS.YIELD_UNIT_CODE = 'GPH'  THEN 'c4634b4847c311e7a91992ebcb67fe33'
    WHEN WELLS.WELLS_WELLS.YIELD_UNIT_CODE = 'UNK'  THEN 'c463518847c311e7a91992ebcb67fe33'
    ELSE NULL
  END AS well_yield_unit_guid,
  WELLS.WELLS_WELLS.LATITUDE,
  WELLS.WELLS_WELLS.LONGITUDE,
  WELLS.WELLS_WELLS.UTM_NORTH,
  WELLS.WELLS_WELLS.UTM_EAST,
  WELLS.WELLS_WELLS.UTM_ZONE_CODE
FROM WELLS.WELLS_WELLS
LEFT OUTER JOIN WELLS.WELLS_OWNERS
ON WELLS.WELLS_OWNERS.OWNER_ID = WELLS.WELLS_WELLS.OWNER_ID
/
SPOOL OFF

/* 111402 */



SET ECHO OFF
SET VERIFY OFF
SPOOL H:\xform_gwells_driller.csv

SELECT /*csv*/ 
  INITCAP(TRIM(WELLS.WELLS_WELLS.CREW_DRILLER_NAME)) AS first_name,
  INITCAP(TRIM(CREW_DRILLER_NAME)) AS surname,
  '1234' AS registration_number,
  'N' AS is_hidden,
  SYS_GUID() AS driller_guid,
  WELLS.WELLS_WELLS.DRILLER_COMPANY_CODE 
FROM WELLS.WELLS_WELLS
WHERE WELLS.WELLS_WELLS.CREW_DRILLER_NAME IS NOT NULL
/
SPOOL OFF


SET ECHO OFF
SET VERIFY OFF
SPOOL H:\xform_gwells_drilling_company.csv

SELECT /*csv*/ 
  DISTINCT WELLS.WELLS_DRILLER_CODES.DRILLER_COMPANY_NAME AS name,
  CASE
     WHEN WELLS.WELLS_DRILLER_CODES.STATUS_FLAG IS NULL THEN 'N'
     WHEN WELLS.WELLS_DRILLER_CODES.STATUS_FLAG = 'N' THEN 'Y'
     WHEN WELLS.WELLS_DRILLER_CODES.STATUS_FLAG = 'Y' THEN 'N'
  END AS is_hidden,  
  SYS_GUID() AS drilling_company_guid,
  WELLS.WELLS_DRILLER_CODES.DRILLER_COMPANY_CODE AS code
FROM WELLS.WELLS_DRILLER_CODES
/
SPOOL OFF





/* In PostGres */

/*
insert into gwells_drilling_company 
values ('Data Conversion Drilling Compnay',
        true,
        '018d4c1047cb11e7a91992ebcb67fe33'
        )
;
*/

