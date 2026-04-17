namespace Backend.Models.Constants;

public static class UserRoles
{
    public const string Admin = "Admin";
    public const string Customer = "Customer";
    public const string LegacyCustomer = "User";
    public const string AdminOrCustomer = Admin + "," + Customer + "," + LegacyCustomer;
}

public static class UserStatuses
{
    public const string Active = "Active";
    public const string Blocked = "Blocked";
}

public static class AccountStatuses
{
    public const string Active = "Active";
    public const string Frozen = "Frozen";
}

public static class TransactionStatuses
{
    public const string PendingApproval = "PendingApproval";
    public const string Completed = "Completed";
    public const string Rejected = "Rejected";
}
