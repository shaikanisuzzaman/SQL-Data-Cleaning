/*
Cleaning Data in SQL Queries
*/


Select *
From NashvilleHousing.dbo.NashvilleHousing

-- Standardize Date Format


Select saleDate, CONVERT(Date,SaleDate)
From NashvilleHousing.dbo.NashvilleHousing

Update NashvilleHousing
SET SaleDate = CONVERT(Date,SaleDate)

----------------------------------------- Populate Property Address data..............................

--- Checking where there is no property address given 
Select PropertyAddress
From NashvilleHousing.dbo.NashvilleHousing
Where PropertyAddress is null

--- Check All Null values  
Select* 
From NashvilleHousing.dbo.NashvilleHousing
Where PropertyAddress is null

--This Property address could be populated if we get breferance points

--- Here we got Parcell id is same for each address

Select PropertyAddress, ParcelID
From NashvilleHousing.dbo.NashvilleHousing
order by ParcelID

--- doing inner join of the table to check that if any Null value is there for the property address then we can populated as per percellid 
Select A.ParcelID, A.PropertyAddress, B.ParcelID, B.PropertyAddress
From NashvilleHousing.dbo.NashvilleHousing A
JOIN NashvilleHousing.dbo.NashvilleHousing B
on A.ParcelID = B.ParcelID
AND A.[UniqueID ]<>B.[UniqueID ] --- We know Unique IDs are not same so it is not the same row
Where A.PropertyAddress is null

-- copy the address if we get null and make a new column for missing address
Select A.ParcelID, A.PropertyAddress, B.ParcelID, B.PropertyAddress, ISNULL(A.PropertyAddress, B.PropertyAddress) -- populate the value if it is null
From NashvilleHousing.dbo.NashvilleHousing A
JOIN NashvilleHousing.dbo.NashvilleHousing B
on A.ParcelID = B.ParcelID
AND A.[UniqueID ]<>B.[UniqueID ] 
Where A.PropertyAddress is null

--- Updating the address for missing property address

Update a -- update
SET PropertyAddress = ISNULL(a.PropertyAddress,b.PropertyAddress)
From NashvilleHousing.dbo.NashvilleHousing A
JOIN NashvilleHousing.dbo.NashvilleHousing B
on A.ParcelID = B.ParcelID
AND A.[UniqueID ]<>B.[UniqueID ] 
Where A.PropertyAddress is null

---------------------------------------------------------------------------------------------------------------------------------------------------
-- Breaking out PropertyAddress into Individual Columns (Address, City, State)


Select PropertyAddress
From NashvilleHousing.dbo.NashvilleHousing

---- We are seperating the address by suburb
Select 
SUBSTRING(PropertyAddress, 1,CHARINDEX(',', PropertyAddress)-1) as RoadName -- staring from 1st character all the way to , thwn -1 to eliminate  , not showing
, SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress)) as Suburb -- Staring from after , then all the way to the end 
From NashvilleHousing.dbo.NashvilleHousing

-- add Column to the table
ALTER TABLE NashvilleHousing
Add PropertySplitAddress Nvarchar(255);

-- add the value for the new column
Update NashvilleHousing
SET PropertySplitAddress = SUBSTRING(PropertyAddress, 1, CHARINDEX(',', PropertyAddress) -1 )

-- add Column to the table
ALTER TABLE NashvilleHousing
Add PropertySplitSuburb Nvarchar(255);

-- Add Value to the newly created column

Update NashvilleHousing
SET PropertySplitSuburb = SUBSTRING(PropertyAddress, CHARINDEX(',', PropertyAddress) + 1 , LEN(PropertyAddress))

--- Check the Updated columns

Select *
From NashvilleHousing.dbo.NashvilleHousing

.........................................................................................

-- Breaking out Owner Address into Individual Columns (Address, City, State)

Select OwnerAddress
From NashvilleHousing.dbo.NashvilleHousing

----- Replacing , with - using parsename
Select
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1) -- replace , with - starting from 1
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)
From NashvilleHousing.dbo.NashvilleHousing

---- making it as order because it does things in reverse order
Select
PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3) as StreetAddress
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2) as Suburb 
,PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1) as State
From NashvilleHousing.dbo.NashvilleHousing

--- Now create new columns and adding those values to the new columns

ALTER TABLE NashvilleHousing
Add OwnerSplitStreetAddress Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitStreetAddress = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 3)


ALTER TABLE NashvilleHousing
Add OwnerSplitSuburb Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitSuburb = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 2)



ALTER TABLE NashvilleHousing
Add OwnerSplitState Nvarchar(255);

Update NashvilleHousing
SET OwnerSplitState = PARSENAME(REPLACE(OwnerAddress, ',', '.') , 1)

--- Checking the updated Table 

Select *
From NashvilleHousing.dbo.NashvilleHousing

--------------------------------------------------------------------------------------------------------------------------------------------------

-- Change Y and N to Yes and No in "Sold as Vacant" field

--- Checking How many yes, no, Y and N

Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From NashvilleHousing.dbo.NashvilleHousing
Group by SoldAsVacant
order by 2

-- changing Y to Yes and N to No
Select SoldAsVacant
, CASE When SoldAsVacant = 'Y' THEN 'Yes'
       When SoldAsVacant = 'N' THEN 'No'
	   Else SoldAsVacant
	   END
From NashvilleHousing.dbo.NashvilleHousing

Update NashvilleHousing
SET SoldAsVacant = CASE When SoldAsVacant = 'Y' THEN 'Yes'
       When SoldAsVacant = 'N' THEN 'No'
	   Else SoldAsVacant
	   END

------ Again Checking how Many Yes and No after the update

Select Distinct(SoldAsVacant), Count(SoldAsVacant)
From NashvilleHousing.dbo.NashvilleHousing
Group by SoldAsVacant
order by 2

------------------------------------------------------------------------------

-- Remove Duplicates


Select*, 
ROW_NUMBER() OVER(
PARTITION BY ParcelID,  --- removing the rows which has got same ParcelID,  PropertyAddress, SalePrice, SaleDate,LegalReferance
             PropertyAddress,
			 SalePrice,
			 SaleDate,
			 LegalReference
			 ORDER BY
			 UniqueID
			 )row_num
From NashvilleHousing.dbo.NashvilleHousing
order by ParcelID


----------- Using CTE as Temp Table with the same query it shows all are duplicates

WITH RowNumCTE AS(
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

From NashvilleHousing.dbo.NashvilleHousing
--order by ParcelID
)
Select *
From RowNumCTE
Where row_num > 1
Order by PropertyAddress

---- Delete the duplicate rows

WITH RowNumCTE AS(
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

From NashvilleHousing.dbo.NashvilleHousing
--order by ParcelID
)
Delete
From RowNumCTE
Where row_num > 1

---  Checking after Deleting duplicate rows if there is any duplicate rows

WITH RowNumCTE AS(
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

From NashvilleHousing.dbo.NashvilleHousing
--order by ParcelID
)
Select *
From RowNumCTE
Where row_num > 1
Order by PropertyAddress

-- Checking the Main Table
Select *
From NashvilleHousing.dbo.NashvilleHousing

---------------------------------------------------------------------------------------------

-- Delete Unused Columns

-- Checking the Main Table
Select *
From NashvilleHousing.dbo.NashvilleHousing

----- Removing a column

ALTER TABLE NashvilleHousing.dbo.NashvilleHousing
DROP COLUMN OwnerAddress, TaxDistrict, PropertyAddress, SaleDate

--- After deleting Column checking the table again

Select *
From NashvilleHousing.dbo.NashvilleHousing

