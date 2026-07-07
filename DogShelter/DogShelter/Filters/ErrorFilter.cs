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
                _ => null
            };

            if (context.Result != null)
            {
                context.ExceptionHandled = true;
            }
            else
            {
                _logger.LogError(ex, "Unhandled exception");
            }
        }
    }
}
