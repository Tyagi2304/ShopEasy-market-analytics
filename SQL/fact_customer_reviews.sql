-- cleaning whitespace issues
SELECT 
    ReviewID, 
    CustomerID,  
    ProductID,  
    ReviewDate,  
    Rating,  
    REPLACE(ReviewText, '  ', ' ') AS ReviewText
FROM 
    customer_reviews;  

    SELECT * FROM customer_reviews