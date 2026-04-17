IF OBJECT_ID(N'[__EFMigrationsHistory]') IS NULL
BEGIN
    CREATE TABLE [__EFMigrationsHistory] (
        [MigrationId] nvarchar(150) NOT NULL,
        [ProductVersion] nvarchar(32) NOT NULL,
        CONSTRAINT [PK___EFMigrationsHistory] PRIMARY KEY ([MigrationId])
    );
END;
GO

BEGIN TRANSACTION;
CREATE TABLE [Users] (
    [Id] int NOT NULL IDENTITY,
    [FirstName] nvarchar(max) NOT NULL,
    [LastName] nvarchar(max) NOT NULL,
    [Email] nvarchar(max) NOT NULL,
    [PasswordHash] nvarchar(max) NOT NULL,
    [Role] nvarchar(max) NOT NULL,
    [Status] nvarchar(max) NOT NULL,
    CONSTRAINT [PK_Users] PRIMARY KEY ([Id])
);

CREATE TABLE [Accounts] (
    [Id] int NOT NULL IDENTITY,
    [AccountName] nvarchar(max) NOT NULL,
    [AccountNumber] nvarchar(max) NOT NULL,
    [Balance] decimal(18,2) NOT NULL,
    [UserId] int NOT NULL,
    [IsMain] bit NOT NULL,
    [Status] nvarchar(max) NOT NULL,
    [ExpiryDate] nvarchar(max) NULL,
    [CVV] nvarchar(max) NULL,
    CONSTRAINT [PK_Accounts] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Accounts_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [Users] ([Id]) ON DELETE CASCADE
);

CREATE TABLE [AuditLogs] (
    [Id] int NOT NULL IDENTITY,
    [UserId] int NULL,
    [Action] nvarchar(max) NOT NULL,
    [Details] nvarchar(max) NULL,
    [Timestamp] datetime2 NOT NULL,
    CONSTRAINT [PK_AuditLogs] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_AuditLogs_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [Users] ([Id]) ON DELETE SET NULL
);

CREATE TABLE [Beneficiaries] (
    [Id] int NOT NULL IDENTITY,
    [Name] nvarchar(max) NOT NULL,
    [AccountNumber] nvarchar(max) NOT NULL,
    [BankName] nvarchar(max) NULL,
    [UserId] int NOT NULL,
    CONSTRAINT [PK_Beneficiaries] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Beneficiaries_Users_UserId] FOREIGN KEY ([UserId]) REFERENCES [Users] ([Id]) ON DELETE CASCADE
);

CREATE TABLE [Transactions] (
    [Id] int NOT NULL IDENTITY,
    [FromAccountId] int NOT NULL,
    [ToAccountId] int NOT NULL,
    [Amount] decimal(18,2) NOT NULL,
    [Type] nvarchar(max) NOT NULL,
    [Status] nvarchar(max) NOT NULL,
    [RequiresApproval] bit NOT NULL,
    [BeneficiaryReference] nvarchar(max) NULL,
    [SenderReference] nvarchar(max) NULL,
    [Timestamp] datetime2 NOT NULL,
    [ReviewedByAdminId] int NULL,
    [ReviewedAt] datetime2 NULL,
    [ReviewNote] nvarchar(max) NULL,
    CONSTRAINT [PK_Transactions] PRIMARY KEY ([Id]),
    CONSTRAINT [FK_Transactions_Accounts_FromAccountId] FOREIGN KEY ([FromAccountId]) REFERENCES [Accounts] ([Id]) ON DELETE NO ACTION,
    CONSTRAINT [FK_Transactions_Accounts_ToAccountId] FOREIGN KEY ([ToAccountId]) REFERENCES [Accounts] ([Id]) ON DELETE NO ACTION
);

CREATE INDEX [IX_Accounts_UserId] ON [Accounts] ([UserId]);

CREATE INDEX [IX_AuditLogs_UserId] ON [AuditLogs] ([UserId]);

CREATE INDEX [IX_Beneficiaries_UserId] ON [Beneficiaries] ([UserId]);

CREATE INDEX [IX_Transactions_FromAccountId] ON [Transactions] ([FromAccountId]);

CREATE INDEX [IX_Transactions_ToAccountId] ON [Transactions] ([ToAccountId]);

INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
VALUES (N'20260417181042_AddAdminRoleSupport', N'9.0.2');

INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
VALUES (N'20260417181126_InitialCreate', N'9.0.2');

INSERT INTO [__EFMigrationsHistory] ([MigrationId], [ProductVersion])
VALUES (N'20260417182541_AddStatusToUser', N'9.0.2');

COMMIT;
GO

