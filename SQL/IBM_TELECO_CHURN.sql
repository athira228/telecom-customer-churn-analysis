/*-------------------------------------
 IBM TELECOM CUSTOMER CHURN ANALYSIS 
 -------------------------------------*/

CREATE DATABASE db_churn;
USE db_churn;

/*Find the row count*/
SELECT COUNT(*) as Total_count
FROM customer_churn;
 /*Insight: 
     Helps me understand dataset size and useful to 
     judge how significant patterns are later*/

/*check duplicates*/
SELECT CustomerID, COUNT(*)
FROM customer_churn
GROUP BY CustomerID
HAVING Count(*)>1;
 /*Insight: 
      Ensuring each customer is unique and 
      duplicates can distort churn rate*/

/*Check null*/
SELECT * 
FROM customer_churn 
WHERE Total_Charges is null 
   OR Total_Charges = ' ';
 /*Insight:
      Missing data could affect analysis and 
      it's essential to maintain clean data */

/* Replacing Churn_Reason Column Null to NO Churn where Customer did not churn*/
UPDATE customer_churn 
SET Churn_Reason = 'No Churn' 
WHERE Churn_Label = 'No' 
AND Churn_Reason IS NULL;
 /*Insight: 
     Makes churn reasons more consistent and clearer*/

/*Replacing missing TotalCharges by assigning zero for new customers with zero tenure*/
UPDATE customer_churn SET Total_Charges = 0 
WHERE Total_Charges IS NULL 
AND Tenure_Months = 0;
/*Insight:
   New customers with zero tenure were assigned zero charges to
   preventing errors in revenue analysis.*/

sp_help customer_churn;

SELECT DISTINCT Churn_Label FROM customer_churn;
SELECT DISTINCT Gender FROM customer_churn;
SELECT DISTINCT Partner FROM customer_churn;
SELECT DISTINCT Dependents FROM customer_churn;
SELECT DISTINCT Phone_service FROM customer_churn;
/*Insight: 
    Exploring unique values to understand categories*/

/*Inspect outliers*/
SELECT 
  MIN(Monthly_Charges) AS Min_Monthly_Charges,
  MAX(Monthly_charges) AS Max_Monthly_Charges
FROM customer_churn;

SELECT 
  MIN(Total_Charges) AS Min_total_Charges,
  MAX(Total_Charges) AS Max_total_Charges
FROM customer_churn;

SELECT * 
FROM customer_churn 
WHERE Monthly_Charges > 200 
 OR Monthly_Charges <10;

SELECT Tenure_Months, Total_Charges
 FROM dbo.customer_churn
 ORDER BY Total_Charges DESC;

 /*Insight: Helps spot unusual pricing that might 
   indicate churn risk and data errors*/

/*Create Tenure Group*/
ALTER TABLE customer_churn
ADD Tenure_Group NVARCHAR(50);

UPDATE customer_churn SET Tenure_Group =
CASE
WHEN Tenure_Months <= 12 THEN '0-1 Year'
WHEN Tenure_Months <= 24 THEN '1-2 Year'
WHEN Tenure_Months <= 48 THEN '2-3 Year'
ELSE '4YEAR+'
END
FROM customer_churn;

 /*Insight: Tenure Grouping helps identify churn trends
   across different customer lifecycle stages*/

/*Creating view for churn analysis*/

CREATE VIEW vw_churn_analysis AS
SELECT *,
    CASE
        WHEN Monthly_Charges > 80 THEN 'High'
        WHEN Monthly_Charges > 50 THEN 'Medium'
        ELSE 'Low'
    END AS Charge_Group,

    CASE
        WHEN Churn_Score > 80 THEN 'High Risk'
        WHEN Churn_Score > 50 THEN 'Medium Risk'
        ELSE 'Low Risk'
    END AS Risk_Category
FROM customer_churn;

select * FROM vw_churn_analysis;

/*Insight: 
      This view helps quickly identify customers with 
    high monthly charges and high churn risk*/

/*calculate overall churn rate*/

SELECT 
    COUNT(*) AS Total_Customers,
    SUM(CASE WHEN Churn_Label = 'Yes' THEN 1 ELSE 0 END) AS Churned_Customers,
    ROUND(
        SUM(CASE WHEN Churn_Label = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS Churn_Percentage
FROM customer_churn;

/*Insight: calculates the overall churn rate by showing total customers, 
     number of churned customers, and churn percentage, shows how many 
	 customers left the company and helps understand customer loss*/

/*Find active customers*/
SELECT COUNT(*) AS Total_customers 
FROM Customer_churn 
where Churn_label = 'No';

/*Insight: Helps understand current retained customers*/

/*Find churn by gender*/
SELECT Gender, COUNT(*) AS Total ,
SUM(CASE WHEN Churn_Label = 'Yes' THEN 1 ELSE 0
END) AS Churned
FROM customer_churn 
GROUP BY Gender;

/*Insight: helps identify which gender group has more customers leaving, 
     useful for demographic targeting*/

/*Churn by Contract Type*/
SELECT 
       Contract, 
COUNT(*)AS Total_Customers,
SUM(CASE WHEN Churn_Label= 'YES' THEN 1 ELSE 0 END) AS Churned,
ROUND(
SUM(CASE WHEN churn_label= 'YES' THEN 1 ELSE 0 END)*100.0/COUNT(*),
2) AS Churn_Rate
FROM customer_churn
GROUP BY Contract
ORDER BY Churn_Rate DESC;

/*Insight: helps identify which contract plans have the highest customer loss,
    Month-to-month customers typically show the highest churn here*/

/*Churn by Tenure Group*/
SELECT 
    Tenure_Group,
    COUNT(*) AS Total_Customers,
    SUM(CASE WHEN Churn_Label = 'Yes' THEN 1 ELSE 0 END) AS Churned_Customer,
    ROUND(
        SUM(CASE WHEN Churn_Label = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 1) AS Churn_Rate
FROM customer_churn
GROUP BY Tenure_Group
ORDER BY Tenure_Group ASC;

/*Insight: helps identify which customer groups are more likely to leave based on 
    how long they have stayed, Early-stage customers often churn more here*/

/*Churn by Charge Group*/
SELECT 
    Charge_Group,
    COUNT(*) AS Total_Customers,
    SUM(CASE WHEN Churn_Label = 'Yes' THEN 1 ELSE 0 END) AS Churned_Customers,
    ROUND(
        SUM(CASE WHEN Churn_Label = 'Yes' THEN 1 ELSE 0 END) * 100.0 / COUNT(*), 2) AS Churn_Rate
FROM vw_churn_analysis
GROUP BY Charge_Group;

/*Insight: Customers with higher monthly charges may churn more,
   suggesting pricing sensitivity impacts retention*/

/*Revenue Loss*/
SELECT 
   SUM(Monthly_charges) AS Revenue_Lost
From customer_churn
where Churn_Label = 'YES';

/*Insight: Churn directly impacts monthly revenue,
   making customer retention financially critical*/

/*customer segmentation analysis by churn risk */

SELECT 
    Risk_Category,
    COUNT(*) AS Total_Customers
FROM vw_churn_analysis
GROUP BY Risk_Category
ORDER BY Total_Customers DESC;

/*Insight: Identifies distribution of customers by churn risk, helping prioritize retention efforts*/

/*High-Risk Customer Identification*/
SELECT COUNT(*) AS High_Risk_Customers
FROM vw_churn_analysis WHERE Churn_label ='Yes'
AND Contract = 'Month-to-Month'
AND Tenure_Months<12 AND Monthly_Charges <70;

/*Insight: most vulnerable customers are new, low-commitment users who should be targeted with retention offers*/

/*Churn by Internet Service*/
SELECT 
  Internet_Service,
  COUNT(*) AS Total_Customers,
SUM(CASE WHEN Churn_Label='Yes' THEN 1 ELSE 0 END) AS Churned_Customers,
ROUND
(SUM(CASE WHEN Churn_Label='Yes' THEN 1 ELSE 0 END)*100.0/COUNT(*),2) AS Churn_Rate
FROM customer_churn
GROUP BY Internet_Service;

/*Insight: Different services may have higher churn, indicating service quality or pricing issues*/

/*Churn by Payement*/
SELECT 
  Payment_Method,
COUNT(*) AS Total_Customers,
SUM(CASE WHEN Churn_Label='Yes' THEN 1 ELSE 0 END) AS Churned_Customers
FROM customer_churn
GROUP BY Payment_Method;
/*Insight: Certain payment methods (like electronic check) often show higher churn*/

/*Avg Charges of Churned vs Non-Churned*/

SELECT 
   Churn_Label,
 AVG(Monthly_charges) AS AVG_Monthly,
 AVG(Total_charges) AS AVG_Total
FROM customer_churn
GROUP BY Churn_Label;

/*Insight: Helps understand if high-paying customers are more likely to churn*/







