using DogShelter.Services.Exceptions;
using DogShelter.Services.Interfaces;
using Microsoft.AspNetCore.Authorization;
using Microsoft.AspNetCore.Mvc;
using Stripe;

namespace DogShelter.Controllers;

[Route("api/webhooks/stripe")]
[ApiController]
public class StripeWebhooksController : ControllerBase
{
    private readonly IStripeWebhookService _stripeWebhookService;
    private readonly ILogger<StripeWebhooksController> _logger;

    public StripeWebhooksController(IStripeWebhookService stripeWebhookService, ILogger<StripeWebhooksController> logger)
    {
        _stripeWebhookService = stripeWebhookService;
        _logger = logger;
    }

    [HttpPost]
    [AllowAnonymous]
    public async Task<IActionResult> Handle()
    {
        using var reader = new StreamReader(Request.Body);
        var json = await reader.ReadToEndAsync();

        try
        {
            var signatureHeader = Request.Headers["Stripe-Signature"].ToString();
            await _stripeWebhookService.ProcessWebhookAsync(json, signatureHeader);
            return Ok();
        }
        catch (StripeException ex)
        {
            _logger.LogError(ex, "Stripe webhook error: {Message}", ex.Message);
            throw new ValidationException($"Stripe webhook error: {ex.Message}");
        }
        catch (Exception ex) when (ex is not (NotFoundException or ValidationException or ForbiddenException or BusinessException or ConflictException))
        {
            _logger.LogError(ex, "Unexpected error while processing Stripe webhook payload");
            throw new ValidationException("Neispravan webhook zahtjev.");
        }
    }
}
