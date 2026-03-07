using Backend.DTOs.Transactions;

namespace Backend.Services;

public interface ITransactionService
{
    Task<TransferResponse> TransferAsync(TransferRequest request);
    Task<TransactionHistoryResponse> GetTransactionHistoryAsync(TransactionHistoryRequest request);
    Task<StatementResponse> GenerateStatementAsync(StatementRequest request, string format = "PDF");
}
