using System.Diagnostics.CodeAnalysis;
using DogShelter.Services.Exceptions;
using Microsoft.EntityFrameworkCore;

namespace DogShelter.Services
{
    internal static class DbUpdateExceptionMapper
    {
        [DoesNotReturn]
        public static void ThrowDeleteConflictOrRethrow(Exception ex, string? conflictMessage = null)
        {
            if (ex is DbUpdateConcurrencyException)
            {
                throw new ConflictException(
                    conflictMessage ?? "Stavka je u međuvremenu izmijenjena ili obrisana. Osvježite stranicu i pokušajte ponovno.");
            }

            if (ex is DbUpdateException dbEx && IsReferenceConstraintViolation(dbEx))
            {
                throw new ConflictException(
                    conflictMessage ?? "Nije moguće obrisati jer se stavka još koristi (npr. u narudžbi, favoritima ili recenzijama).");
            }

            throw ex;
        }

        private static bool IsReferenceConstraintViolation(DbUpdateException ex) =>
            ContainsForeignKeyViolation(GetInnermostMessage(ex));

        private static bool ContainsForeignKeyViolation(string message) =>
            message.Contains("REFERENCE constraint", StringComparison.OrdinalIgnoreCase)
            || message.Contains("FOREIGN KEY", StringComparison.OrdinalIgnoreCase)
            || message.Contains("FK_", StringComparison.OrdinalIgnoreCase)
            || message.Contains("foreign key constraint", StringComparison.OrdinalIgnoreCase)
            || message.Contains("The DELETE statement conflicted", StringComparison.OrdinalIgnoreCase);

        private static string GetInnermostMessage(Exception ex)
        {
            var message = ex.Message;
            for (var inner = ex.InnerException; inner != null; inner = inner.InnerException)
            {
                message = inner.Message;
            }

            return message;
        }
    }
}
