/*
DATA CLEANING 
*/

---------------------------------
SELECT * FROM NashvillHousing


--POPULATE PROPERTY ADDRESS DATE 

SELECT f.ParcelID, f.PropertyAddress, s.ParcelID, s.PropertyAddress,
	  ISNULL(f.PropertyAddress,s.PropertyAddress)
FROM NashvillHousing f 
join NashvillHousing s 
ON f.ParcelID = s.ParcelID	AND f.UniqueID <> s.UniqueID
WHERE f.PropertyAddress IS NULL 


UPDATE f
SET PropertyAddress = ISNULL(f.PropertyAddress,s.PropertyAddress)
FROM NashvillHousing f 
join NashvillHousing s 
ON f.ParcelID = s.ParcelID	AND f.UniqueID <> s.UniqueID
WHERE f.PropertyAddress IS NULL 


-----------------------------

-- SPLIT PropertyAddress to (address, city)

SELECT PropertyAddress,
	SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress) -1) as adress,
	SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress) +1, LEN(PropertyAddress))as city

FROM NashvillHousing


ALTER TABLE NashvillHousing
ADD NewPropertyAddress NVARCHAR(255)

UPDATE  NashvillHousing
SET NewPropertyAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',',PropertyAddress) -1)


ALTER TABLE NashvillHousing
ADD PropertyCity NVARCHAR(255)

UPDATE  NashvillHousing
SET PropertyCity = SUBSTRING(PropertyAddress, CHARINDEX(',',PropertyAddress) +1, LEN(PropertyAddress))



-----------------------------

-- SPLIT OwnerAddress to (address, state, city)

SELECT
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3) AS address,
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2) AS city,
	PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) AS state
FROM NashvillHousing


ALTER TABLE NashvillHousing
ADD OwnerAddresses NVARCHAR(255);

UPDATE  NashvillHousing
SET OwnerAddresses = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 3)



ALTER TABLE NashvillHousing
ADD OwnerCity NVARCHAR(255);

UPDATE  NashvillHousing
SET OwnerCity = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 2)



ALTER TABLE NashvillHousing
ADD OwnerState NVARCHAR(255);

UPDATE  NashvillHousing
SET OwnerState = PARSENAME(REPLACE(OwnerAddress, ',', '.'), 1) 


-----------------------------

--	CHANGE 0 AND 1 TO YES AND NO IN SOLDASVACANT

SELECT
	SoldAsVacant,
	CASE WHEN SoldAsVacant = 0 THEN 'NO' ELSE 'YES' END AS SAV 
FROM NashvillHousing


ALTER TABLE NashvillHousing
ADD SoldAsVacant_text NVARCHAR(10);

UPDATE  NashvillHousing
SET SoldAsVacant_text = CASE WHEN SoldAsVacant = 0 THEN 'NO' ELSE 'YES' END



-----------------------------

--	REMOVE DUPLICATES

With duplicate as (
SELECT *,
	ROW_NUMBER() OVER(
	PARTITION BY ParcelID,
				 PropertyAddress,
				SalePrice,
				SaleDate,
				LegalReference
				ORDER BY 
				UniqueID ) row_num
FROM NashvillHousing )

SELECT * 
FROM duplicate
WHERE row_num > 1 


-----------------------------

--	DELETE Unused Columns 

SELECT * FROM NashvillHousing

ALTER TABLE NashvillHousing
DROP COLUMN  OwnerAddress, TaxDistrict, SoldAsVacant

ALTER TABLE NashvillHousing
DROP COLUMN PropertyAddress