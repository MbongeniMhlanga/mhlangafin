using System.ComponentModel.DataAnnotations;

namespace Backend.DTOs.Transactions;

public class TransactionHistoryResponse
{
    public int TotalTransactions { get; set; }
    public int Page { get; set; }
    public int PageSize { get; set; }
    public int TotalPages { get; set; }
    public List<TransactionDto> Transactions { get; set; } = new List<TransactionDto>();
}

public class TransactionDto
{
    public int Id { get; set; }
    public string Type { get; set; } = null!;
    public decimal Amount { get; set; }
    public string? FromAccountNumber { get; set; }
    public string? ToAccountNumber { get; set; }
    public decimal BalanceAfter { get; set; }
    public string? Description { get; set; }
    public DateTime Timestamp { get; set; }
}
