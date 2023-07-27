/* --------------------
   Case Study Answers
   --------------------*/
   -- 1. What is the total amount each customer spent at the restaurant?
1 
SELECT sales.customer_id, SUM(menu.price) as total_spent
FROM dannys_diner.sales
JOIN dannys_diner.menu ON dannys_diner.sales.product_id = dannys_diner.menu.product_id
GROUP BY sales.customer_id
ORDER BY total_spent desc;

-- 2. How many days has each customer visited the restaurant?

2 
SELECT sales.customer_id, COUNT(sales.order_date)
FROM dannys_diner.sales
GROUP BY sales.customer_id
ORDER BY COUNT(DISTINCT sales.order_date) desc;
*

-- 3. What was the first item from the menu purchased by each customer?


WITH ranked_sales AS (
    SELECT 
        sales.customer_id, 
        menu.product_name,
  		TO_CHAR(sales.order_date, 'YYYY-MM-DD') as order_date,
        ROW_NUMBER() OVER (PARTITION BY sales.customer_id ORDER BY sales.order_date, sales.product_id) as row_num
    FROM 
        dannys_diner.sales
    JOIN 
        dannys_diner.menu ON sales.product_id = menu.product_id
)
SELECT customer_id, product_name, order_date
FROM ranked_sales
WHERE row_num = 1;
*

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
   SELECT menu.product_name as most_purchased_item, COUNT(sales.order_date) as order_count
   FROM dannys_diner.menu
   JOIN dannys_diner.sales ON dannys_diner.sales.product_id=dannys_diner.menu.product_id
   GROUP BY most_purchased_item
   ORDER BY order_count desc
   limit(1);



-- 5. Which item was the most popular for each customer?

WITH customer_favorites as (
  SELECT 
    sales.customer_id,
    COUNT(sales.order_date) as order_times,
    menu.product_name,
    ROW_NUMBER() OVER (PARTITION BY sales.customer_id ORDER BY COUNT(sales.order_date) DESC) as row_num
  FROM 
    dannys_diner.sales 
  JOIN 
    dannys_diner.menu 
  ON 
    dannys_diner.sales.product_id=dannys_diner.menu.product_id
  GROUP BY 
    sales.customer_id,
    menu.product_name
)

SELECT 
  customer_id,
  order_times,
  product_name
FROM 
  customer_favorites
WHERE 
  row_num = 1;

-- 6. Which item was purchased first by the customer after they became a member?

WITH first_purchase AS (
  SELECT 
    sales.customer_id,
    sales.order_date,
    members.join_date,
    menu.product_name,
    ROW_NUMBER() OVER (PARTITION BY sales.customer_id ORDER BY sales.order_date) as row_num
  FROM 
    dannys_diner.sales 
  JOIN 
    dannys_diner.menu 
  ON 
    dannys_diner.sales.product_id=dannys_diner.menu.product_id
  JOIN 
    dannys_diner.members 
  ON 
    dannys_diner.sales.customer_id = dannys_diner.members.customer_id
  WHERE 
    sales.order_date >= members.join_date
)

SELECT 
  customer_id,
  join_date,
  order_date,
  product_name
FROM 
  first_purchase
WHERE 
  row_num = 1;

-- 7. Which item was purchased just before the customer became a member?
WITH purchase AS (
    SELECT 
        sales.customer_id,
        TO_CHAR(sales.order_date, 'YYYY-MM-DD') as order_date,
        TO_CHAR(members.join_date, 'YYYY-MM-DD') as join_date,
        menu.product_id,
        menu.product_name,
        ROW_NUMBER() OVER (PARTITION BY sales.customer_id ORDER BY sales.order_date DESC) as row_num
    FROM 
        dannys_diner.sales 
    JOIN 
        dannys_diner.menu 
    ON 
        sales.product_id = menu.product_id
    JOIN 
        dannys_diner.members 
    ON 
        sales.customer_id = members.customer_id
    WHERE 
        sales.order_date < members.join_date
)
SELECT 
    customer_id,
    join_date,
    order_date,
    product_id,
    product_name
FROM 
    purchase
WHERE 
    row_num = 1;
-- 8. What is the total items and amount spent for each member before they became a member?
WITH pre_membership_purchases AS (
    SELECT 
        sales.customer_id,
        menu.product_name,
        menu.price,
        members.join_date,
        sales.order_date
    FROM 
        dannys_diner.sales 
    JOIN 
        dannys_diner.menu 
    ON 
        sales.product_id = menu.product_id
    JOIN 
        dannys_diner.members 
    ON 
        sales.customer_id = members.customer_id
    WHERE 
        sales.order_date < members.join_date
)
SELECT 
    customer_id,
    COUNT(product_name) as total_items,
    SUM(price) as total_spent
FROM 
    pre_membership_purchases
GROUP BY
    Customer_id;
    
-- 9.  If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

SELECT sales.customer_id,
	SUM( CASE WHEN menu.product_name='sushi' then menu.price*20 else menu.price*10
        END) as total_points
FROM 
		dannys_diner.sales 
    JOIN 
        dannys_diner.menu 
    ON 
        sales.product_id = menu.product_id
GROUP BY sales.customer_id
ORDER BY total_points DESC;

-- 10. In the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?
 WITH points AS (
    SELECT 
        sales.customer_id,
        sales.order_date,
        members.join_date,
        menu.price,
        CASE
            WHEN sales.order_date BETWEEN members.join_date AND members.join_date + INTERVAL '7 days' THEN 2
            ELSE 1
        END as multiplier
    FROM 
        dannys_diner.sales 
    JOIN 
        dannys_diner.menu 
    ON 
        sales.product_id = menu.product_id
    JOIN 
        dannys_diner.members 
    ON 
        sales.customer_id = members.customer_id
    WHERE 
        sales.order_date <= '2021-01-31'
)
SELECT 
    customer_id,
    SUM(price * 10 * multiplier) as total_points
FROM 
    points
GROUP BY 
    customer_id;



