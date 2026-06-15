USE olist;

-- Dimension Tables
CREATE TABLE customers (
    customer_id VARCHAR(50) PRIMARY KEY,
    customer_unique_id VARCHAR(50) NOT NULL,
    customer_zip_code_prefix VARCHAR(10),
    customer_city VARCHAR(50),
    customer_state CHAR(2)
);

CREATE TABLE products (
    product_id VARCHAR(50) PRIMARY KEY,
    product_category_name VARCHAR(50),
    product_name_lenght INT,
    product_description_lenght INT,
    product_photos_qty INT,
    product_weight_g INT,
    product_length_cm INT,
    product_height_cm INT,
    product_width_cm INT
);

CREATE TABLE sellers (
    seller_id VARCHAR(50) PRIMARY KEY,
    seller_zip_code_prefix VARCHAR(10),
    seller_city VARCHAR(50),
    seller_state CHAR(2)
);

-- Fact Tables
CREATE TABLE orders (
    order_id VARCHAR(50) PRIMARY KEY,
    customer_id VARCHAR(50),
    order_status VARCHAR(20),
    order_purchase_timestamp DATETIME,
    order_approved_at DATETIME,
    order_delivered_carrier_date DATETIME,
    order_delivered_customer_date DATETIME,
    order_estimated_delivery_date DATETIME,
    FOREIGN KEY (customer_id) REFERENCES customers(customer_id)
);

CREATE TABLE order_items (
    order_id VARCHAR(50),
    order_item_id INT,
    product_id VARCHAR(50),
    seller_id VARCHAR(50),
    shipping_limit_date DATETIME,
    price DECIMAL(10, 2),
    freight_value DECIMAL(10, 2),
    PRIMARY KEY (order_id, order_item_id),
    FOREIGN KEY (order_id) REFERENCES orders(order_id),
    FOREIGN KEY (product_id) REFERENCES products(product_id),
    FOREIGN KEY (seller_id) REFERENCES sellers(seller_id)
);

CREATE TABLE order_payments (
    order_id VARCHAR(50),
    payment_sequential INT,
    payment_type VARCHAR(20),
    payment_installments INT,
    payment_value DECIMAL(10, 2),
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);

CREATE TABLE order_reviews (
    review_id VARCHAR(50),
    order_id VARCHAR(50),
    review_score INT,
    review_comment_title VARCHAR(255),
    review_comment_message TEXT,
    review_creation_date DATETIME,
    review_answer_timestamp DATETIME,
    -- No primary key here as some orders have multiple reviews
    FOREIGN KEY (order_id) REFERENCES orders(order_id)
);


CREATE TABLE geolocation (
    geolocation_zip_code_prefix VARCHAR(10),
    geolocation_lat DOUBLE,
    geolocation_lng DOUBLE,
    geolocation_city VARCHAR(50),
    geolocation_state CHAR(2)
    -- This table does not have a strict primary key in the dataset, 
    -- as there are multiple coordinates for the same zip code prefix.
);

CREATE TABLE product_category_name_translation (
    product_category_name VARCHAR(50) PRIMARY KEY,
    product_category_name_english VARCHAR(50)
);

SELECT * FROM customers
limit 5;

WITH OrderAggregates AS (
    SELECT 
        c.customer_unique_id,
        o.order_id,
        o.order_purchase_timestamp,
        SUM(p.payment_value) AS total_order_value
    FROM orders o
    JOIN customers c 
        ON o.customer_id = c.customer_id
    JOIN order_payments p 
        ON o.order_id = p.order_id
    WHERE o.order_status = 'delivered' 
    GROUP BY 
        c.customer_unique_id, 
        o.order_id, 
        o.order_purchase_timestamp
)
SELECT 
    customer_unique_id,
    order_id,
    order_purchase_timestamp,
    total_order_value,
    ROW_NUMBER() OVER(
        PARTITION BY customer_unique_id 
        ORDER BY order_purchase_timestamp
    ) AS customer_order_rank
FROM OrderAggregates;

-- Turn off Foreign Key checks so MySQL lets us delete things
SET FOREIGN_KEY_CHECKS = 0;

TRUNCATE TABLE order_reviews;
TRUNCATE TABLE order_payments;
TRUNCATE TABLE order_items;
TRUNCATE TABLE orders;
TRUNCATE TABLE customers;
TRUNCATE TABLE products;
TRUNCATE TABLE sellers;
TRUNCATE TABLE geolocation;
TRUNCATE TABLE product_category_name_translation;

-- Turn Foreign Key checks back on!
SET FOREIGN_KEY_CHECKS = 1;