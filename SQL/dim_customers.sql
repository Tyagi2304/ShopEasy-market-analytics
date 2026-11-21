SELECT * FROM customerS;

SELECT * FROM geography;

--ENRICHING customer data with geography info
SELECT 
    c.CustomerID,  
    c.CustomerName,  
    c.Email,  
    c.Gender,  
    c.Age, 
    g.Country,  
    g.City  
FROM customers as c  
LEFT JOIN geography g  
ON c.GeographyID = g.GeographyID;  