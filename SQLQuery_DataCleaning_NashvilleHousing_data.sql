--1) Standardize Date Format and update the table with this change

Select SaleDate, CONVERT(Date,SaleDate)
From Portfolio_Project.dbo.NashvilleHousing_CSV

Update NashvilleHousing_CSV
SET SaleDate = CONVERT(Date,SaleDate)



--2)  Populate Property Address data using JOIN on the table

Select *
From Portfolio_Project.dbo.NashvilleHousing_CSV
Where PropertyAddress is null
order by ParcelID --show all records eith NULL entires in Property_Adress

Select *
From Portfolio_Project.dbo.NashvilleHousing_CSV
order by ParcelID --see full set of data and notice a paritcular PacelID number matches with particular Property Address. This can be used to find the Null values.   


Select a.ParcelID, a.PropertyAddress, b.ParcelID, b.PropertyAddress, ISNULL(a.PropertyAddress,b.PropertyAddress) --if a.PropertyAddress is NULL then populate it with b.PropertyAddress addresses
From Portfolio_Project.dbo.NashvilleHousing_CSV a
JOIN Portfolio_Project.dbo.NashvilleHousing_CSV b --do an internal JOIN 
	on a.ParcelID = b.ParcelID 
	AND a.[UniqueID] <> b.[UniqueID]  --assuming the UniqueID is different for same ParcelID entires 
Where a.PropertyAddress is null


Update a --the 'no column name' column will be inserted into a.PropertyAddress Null list
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
From Portfolio_Project.dbo.NashvilleHousing_CSV a
JOIN Portfolio_Project.dbo.NashvilleHousing_CSV b
	on a.ParcelID = b.ParcelID
	AND a.[UniqueID] <> b.[UniqueID]
Where a.PropertyAddress is null --if updated successfully no data will be shown as NULLS have been changed to addresses

SELECT PropertyAddress --check that there are no nulls in the column
From Portfolio_Project.dbo.NashvilleHousing_CSV




--3) Breaking up PropertyAddress into Individual Columns (Address, City, State)
--a) From PropertyAddress column create 2 new columns PropertySplitAddress and PropertySplitCity 
Select PropertyAddress --see the address column
From Portfolio_Project.dbo.NashvilleHousing_CSV


SELECT
SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 ) as Address1 --take address up to the comma, -1 so that the comma is removed from cell
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress)) as Address2 --+1 to start a character after the comma and up to the legnth of address

From Portfolio_Project.dbo.NashvilleHousing_CSV


ALTER TABLE NashvilleHousing_CSV --need to create two new columns and not just a selection done above
Add PropertySplitAddress Nvarchar(255);

Update NashvilleHousing_CSV
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 )

ALTER TABLE NashvilleHousing_CSV
Add PropertySplitCity Nvarchar(255);

Update NashvilleHousing_CSV
SET PropertySplitCity = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress))

Select * --view the updated table with two extra columns at the end
From Portfolio_Project.dbo.NashvilleHousing_CSV


--b) From OwnerAddress column create 3 new columns OwnerSplitAddress, OwnerSplitCity and OwnerSplitState 
Select OwnerAddress -- see how OwnerAddress column also needs to be split
From Portfolio_Project.dbo.NashvilleHousing_CSV

Select
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3) --parsename only works to separate fullstops, so first replace all commas ',' with a fullstop '.'
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)
From Portfolio_Project.dbo.NashvilleHousing_CSV

ALTER TABLE NashvilleHousing_CSV --add the 3 extra columns to the data by alter function
Add OwnerSplitAddress Nvarchar(255);

Update NashvilleHousing_CSV
SET OwnerSplitAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)

ALTER TABLE NashvilleHousing_CSV
Add OwnerSplitCity Nvarchar(255);

Update NashvilleHousing_CSV
SET OwnerSplitCity = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)


ALTER TABLE NashvilleHousing_CSV
Add OwnerSplitState Nvarchar(255);

Update NashvilleHousing_CSV
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)

Select * --see resultant table with additional columns at the end
From Portfolio_Project.dbo.NashvilleHousing_CSV





--4) Change 1 and 0 to Yes and No in "Sold as Vacant" field

Select *
From Portfolio_Project.dbo.NashvilleHousing_CSV


Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From Portfolio_Project.dbo.NashvilleHousing_CSV
Group by SoldAsVacant
order by 2


ALTER TABLE NashvilleHousing_CSV
Add Sold Nvarchar(255); --create a new column called Sold

Select SoldAsVacant, Sold 
From Portfolio_Project.dbo.NashvilleHousing_CSV


Update NashvilleHousing_CSV --input 0 for No and 1 for Yes into sold column
SET Sold = CASE	WHEN SoldAsVacant = 1 THEN 'Yes' 
		ELSE 'No' 
		END

Select *     --view newly populated column at end of table
From Portfolio_Project.dbo.NashvilleHousing_CSV




--5) Remove Duplicates
--a) first run Create the CTE table and view duplicates
WITH RowNumCTE AS( --create a CTE to remove duplicates 
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

From Portfolio_Project.dbo.NashvilleHousing_CSV
--this will give new column called row_num whcih will show 1s if all other columns combinations are unique but a 2 if the row is a duplicate
)

Select *
From RowNumCTE --make CTE so that it includes row_num and can be processed
Where row_num > 1 --display rows in CTE where row_num is more than 1 (duplicates)
Order by PropertyAddress

--b) Second run Delete the duplicates row_num =2

WITH RowNumCTE AS( --create a CTE to remove duplicates 
Select *,
	ROW_NUMBER() OVER (
	PARTITION BY ParcelID,
				 PropertyAddress,
				 SalePrice,
				 SaleDate,
				 LegalReference
				 ORDER BY
					UniqueID
					) row_num

From Portfolio_Project.dbo.NashvilleHousing_CSV
--this will give new column called row_num whcih will show 1s if all other columns combinations are unique but a 2 if the row is a duplicate
)
Delete
FROM RowNumCTE --delete the above selected duplicates
WHERE row_num > 1


--c) third run 
--Run a) again to check that there is no rows anymore in the RowNumCTE





--6) Delete Unused Columns

Select *
From Portfolio_Project.dbo.NashvilleHousing_CSV

ALTER TABLE Portfolio_Project.dbo.NashvilleHousing_CSV
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate

Select * --check that columns are gone
From Portfolio_Project.dbo.NashvilleHousing_CSV
