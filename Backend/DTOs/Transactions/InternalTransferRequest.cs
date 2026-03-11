namespace Backend.DTOs.Transactions;

public class InternalTransferRequest
{
    public int FromAccountId { get; set; }
    public int ToAccountId { get; set; }
    public decimal Amount { get; set; }
}
