select
    *
from
    dbo.members;
-------------------

select
    *
from
    dbo.menu;

-------------------
select
    *
from
    dbo.sales;

-- 1. What is the total amount each customer spent at the restaurant?

select
    customer_id,
    sum(price) as total_amount
from
    dbo.sales
    join dbo.menu on dbo.sales.product_id = dbo.menu.product_id
group by
    customer_id;

-- 2. How many days has each customer visited the restaurant?

select
    customer_id,
    count(distinct(order_date))
from
    dbo.sales
group by
    customer_id;

-- 3. What was the first item from the menu purchased by each customer?

with cte as (
    select
        customer_id,
        product_name,
        row_number() over(
            partition by customer_id
            order by
                order_date
        ) as row_number
    from
        dbo.sales
        join dbo.menu on dbo.sales.product_id = dbo.menu.product_id
)
select
    customer_id,
    product_name
from
    cte
where
    row_number = 1;

-- 4. What is the most purchased item on the menu and how many times was it purchased by all customers?
-- most purchased item

select
    product_name
from
    menu
where
    product_id = (
        select
            top 1 product_id
        from
            dbo.sales
        group by
            product_id
        order by
            count(product_id) desc
    );

-- how many times was it purchased by all customers

select
    customer_id,
    count(*) as 'preched_items_count'
from
    dbo.sales
where
    product_id = (
        select
            top 1 product_id
        from
            dbo.sales
        group by
            product_id
        order by
            count(product_id) desc
    )
group by
    customer_id;

-- 5. Which item was the most popular for each customer?

select
    distinct customer_id,
    menu.product_name
from
    sales s
    join menu on menu.product_id = s.product_id
where
    s.product_id = (
        select
            top 1 product_id
        from
            sales
        where
            customer_id = s.customer_id
        group by
            product_id
        order by
            count(product_id) desc
    );

-- 6. Which item was purchased first by the customer after they became a member?

with cte as (
    select
        s.customer_id,
        s.product_id,
        s.order_date
    from
        sales s
        join members m on s.customer_id = m.customer_id
    where
        s.order_date > m.join_date
),
cte2 as (
    select
        *,
        row_number() over(
            partition by customer_id
            order by
                order_date
        ) as cout
    from
        cte
)
select
    customer_id,
    product_id,
    order_date
from
    cte2
where
    cout = 1;

-- 7. Which item was purchased just before the customer became a member?

with cte as (
    select
        s.customer_id,
        s.product_id,
        s.order_date
    from
        sales s
        join members m on s.customer_id = m.customer_id
    where
        s.order_date < m.join_date
),
cte2 as (
    select
        *,
        row_number() over(
            partition by customer_id
            order by
                order_date desc
        ) as cout
    from
        cte
)
select
    customer_id,
    product_id,
    order_date
from
    cte2
where
    cout = 1;

-- 8. What is the total items and amount spent for each member before they became a member?

with cte as (
    select
        s.customer_id,
        s.product_id,
        s.order_date,
        m.join_date,
        price
    from
        sales s
        join members m on s.customer_id = m.customer_id
        join menu mn on mn.product_id = s.product_id
    where
        s.order_date < m.join_date
)
select
    cte.customer_id,
    count(*) as 'total_item',
    sum(price) as 'total_amount'
from
    cte
group by
    customer_id;

-- 9. If each $1 spent equates to 10 points and sushi has a 2x points multiplier - how many points would each customer have?

select
    s.customer_id,
    sum(
        case
            when product_name = 'sushi' then m.price * 20
            else price * 10
        end
    ) as 'points'
from
    sales s
    join menu m on s.product_id = m.product_id
group by
    s.customer_id;

-- 10. n the first week after a customer joins the program (including their join date) they earn 2x points on all items, not just sushi - how many points do customer A and B have at the end of January?

select
    s.customer_id,
    sum(
        case
            when order_date <= dateadd(day, 6, join_date) then price * 20
            when order_date >= dateadd(day, 6, join_date)
            and s.product_id = 1 then price * 20
            else price * 10
        end
    ) as 'points'
from
    sales s
    join members m on s.customer_id = m.customer_id
    join menu mn on mn.product_id = s.product_id
where
    s.order_date >= m.join_date
    AND s.order_date < CAST('2021-02-01' AS DATE)
group by
    s.customer_id;

-- ADVANCE QUESTIONS : 1

select
    s.customer_id,
    order_date,
    product_name,
    price,
    case
        when s.customer_id in (
            select
                s.customer_id
            from
                members
        )
        and order_date >= join_date then 'Y'
        ELSE 'N'
    END AS 'MEMBER'
from
    sales s
    join menu m on m.product_id = s.product_id
    left join members mb on s.customer_id = mb.customer_id;

-- ADVANCE QUESTIONS : 2

with cte as (
    select
        s.customer_id,
        order_date,
        product_name,
        price,
        case
            when s.customer_id in (
                select
                    s.customer_id
                from
                    members
            )
            and order_date >= join_date then 'Y'
            ELSE 'N'
        END AS 'MEMBER'
    from
        sales s
        join menu m on m.product_id = s.product_id
        left join members mb on s.customer_id = mb.customer_id
)
select
    *,
    case
        when member = 'Y' then dense_rank() over(
            partition by customer_id,
            member
            order by
                order_date
        )
        else null
    end as 'rank'
from
    cte;
