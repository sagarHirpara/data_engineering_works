-- Procedure for the get the client details
CREATE PROCEDURE sp_GetClientDetails @ ClientId INT AS BEGIN
SELECT
    c.ClientId,
    c.Status,
    c.Name AS 'Client name',
    pc.Name AS 'Parent Client',
    sp.Name AS 'Service plan',
    sp.StartDate AS 'Plan start date',
    sp.EndDate AS 'Plan end date',
    c.Address,
    sr.Rate AS 'Solicitor rate',
    lar.Rate AS 'Legal Assistant rate',
    SUM(i.Amount) AS 'Total invoiced'
FROM
    Clients c
    LEFT JOIN ServicePlans sp ON c.ServicePlanId = sp.ServicePlanId
    LEFT JOIN Clients pc ON c.ParentClientId = pc.ClientId
    LEFT JOIN Rates sr ON sr.RateId = sp.SolicitorRateId
    LEFT JOIN Rates lar ON lar.RateId = sp.LegalAssistantRateId
    LEFT JOIN Invoices i ON i.ClientId = c.ClientId
WHERE
    c.ClientId = @ ClientId
GROUP BY
    c.ClientId,
    c.Status,
    c.Name,
    pc.Name,
    sp.Name,
    sp.StartDate,
    sp.EndDate,
    c.Address,
    sr.Rate,
    lar.Rate
END -- Improving the performence using indexing
-- 1 . Clients table: create a clustered index on the primary key column (ClientId),
-- and create a non-clustered index on the column used in the WHERE clause (ClientId).


CREATE CLUSTERED INDEX IX_Clients_ClientId ON Clients(ClientId) 
CREATE NONCLUSTERED INDEX IX_Clients_ClientId ON Clients(ClientId) 

-- 2. ServicePlans table: create a clustered index on the primary key column (ServicePlanId),
-- and create a non-clustered index on the column used in the JOIN clause (ServicePlanId).


CREATE CLUSTERED INDEX IX_ServicePlans_ServicePlanId ON ServicePlans(ServicePlanId) 
CREATE NONCLUSTERED INDEX IX_ServicePlans_ServicePlanId ON ServicePlans(ServicePlanId) 

-- 3. Clients table (again): create a non-clustered index on the column used in the JOIN clause (ParentClientId).

CREATE NONCLUSTERED INDEX IX_Clients_ParentClientId ON Clients(ParentClientId) 

-- 4. Rates table: create a clustered index on the primary key column (RateId),
-- and create non-clustered indexes on the columns used in the JOIN clause
-- (SolicitorRateId and LegalAssistantRateId).


CREATE CLUSTERED INDEX IX_Rates_RateId ON Rates(RateId) 
CREATE NONCLUSTERED INDEX IX_Rates_SolicitorRateId ON Rates(SolicitorRateId) 
CREATE NONCLUSTERED INDEX IX_Rates_LegalAssistantRateId ON Rates(LegalAssistantRateId) 

-- 5. Invoices table: create a non-clustered index on the column used in the JOIN clause (ClientId).
CREATE NONCLUSTERED INDEX IX_Invoices_ClientId ON Invoices(ClientId)
