using Backend.DTOs.Transactions;

namespace Backend.Services;

public interface ITransactionService
{
    Task<TransferResponse> TransferAsync(TransferRequest request, int requesterUserId, bool isAdmin);
    Task<TransferResponse> InternalTransferAsync(InternalTransferRequest request, int requesterUserId, bool isAdmin);
    Task<TransactionHistoryResponse> GetTransactionHistoryAsync(TransactionHistoryRequest request, int requesterUserId, bool isAdmin);
    Task<StatementResponse> GenerateStatementAsync(StatementRequest request, int requesterUserId, bool isAdmin, string format = "PDF");
}
