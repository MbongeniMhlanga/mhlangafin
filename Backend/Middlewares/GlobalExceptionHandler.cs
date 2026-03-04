using Microsoft.AspNetCore.Diagnostics;
using Microsoft.AspNetCore.Mvc;

namespace Backend.Middlewares;

public static class ExceptionHandlerMiddlewareExtensions
{
    public static void ConfigureExceptionHandler(this IApplicationBuilder app)
    {
        app.UseExceptionHandler(appError =>
        {
            appError.Run(async context =>
            {
                context.Response.ContentType = "application/json";

                var contextFeature = context.Features.Get<IExceptionHandlerFeature>();
                if (contextFeature != null)
                {
                    var statusCode = contextFeature.Error switch
                    {
                        InvalidOperationException => StatusCodes.Status400BadRequest,
                        KeyNotFoundException => StatusCodes.Status404NotFound,
                        _ => StatusCodes.Status500InternalServerError
                    };

                    context.Response.StatusCode = statusCode;

                    var errorResponse = new ProblemDetails
                    {
                        Status = statusCode,
                        Title = "An error occurred while processing your request.",
                        Detail = contextFeature.Error.Message
                    };

                    await context.Response.WriteAsJsonAsync(errorResponse);
                }
            });
        });
    }
}
