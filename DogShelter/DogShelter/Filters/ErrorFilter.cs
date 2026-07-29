using DogShelter.Services.Exceptions;
using Microsoft.AspNetCore.Mvc;
using Microsoft.AspNetCore.Mvc.Filters;

namespace DogShelter.Filters
{
    public class ErrorFilter : IExceptionFilter
    {
        private readonly ILogger<ErrorFilter> _logger;

        public ErrorFilter(ILogger<ErrorFilter> logger)
        {
            _logger = logger;
        }

        public void OnException(ExceptionContext context)
        {
            var ex = context.Exception;

            context.Result = ex switch
            {
                NotFoundException => new NotFoundObjectResult(new { message = ex.Message }),
                ForbiddenException => new ObjectResult(new { message = ex.Message }) { StatusCode = 403 },
                ValidationException ve => new BadRequestObjectResult(new
                {
                    message = ve.Message,
                    errors = ve.Errors
                }),
                BusinessException => new BadRequestObjectResult(new { message = ex.Message }),
                ConflictException => new ConflictObjectResult(new { message = ex.Message }),
                _ => new ObjectResult(new { message = "Došlo je do neočekivane greške. Pokušajte ponovo kasnije." })
                {
                    StatusCode = 500
                }
            };

            context.ExceptionHandled = true;

            if (ex is NotFoundException or ForbiddenException or ValidationException or BusinessException or ConflictException)
            {
                _logger.LogWarning(ex, "Handled {ExceptionType}: {Message}", ex.GetType().Name, ex.Message);
            }
            else
            {
                _logger.LogError(ex, "Unhandled exception");
            }
        }
    }
}
