namespace Backend.DTOs.Admin;

public class AdminStatsDto
{
    public int TotalUsers { get; set; }
    public int TotalCustomers { get; set; }
    public int TotalAdmins { get; set; }
    public int ActiveUsers { get; set; }
    public int BlockedUsers { get; set; }
    public int TotalAccounts { get; set; }
    public int FrozenAccounts { get; set; }
    public int PendingTransactions { get; set; }
    public int CompletedTransactions { get; set; }
    public int RejectedTransactions { get; set; }
    public decimal TotalCompletedTransactionVolume { get; set; }
}
