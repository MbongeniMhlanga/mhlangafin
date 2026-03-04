namespace Backend.DTOs.Transactions;

public class TransferResponse
{
    public int TransactionId { get; set; }
    public string Status { get; set; } = null!;
    public string Message { get; set; } = null!;
}
