using Backend.DTOs.Transactions;

namespace Backend.Services;

public interface ITransactionService
{
    Task<TransferResponse> TransferAsync(TransferRequest request);
}
