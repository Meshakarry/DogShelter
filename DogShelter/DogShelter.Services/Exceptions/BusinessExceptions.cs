namespace DogShelter.Services.Exceptions
{
    public class NotFoundException : Exception
    {
        public NotFoundException(string message) : base(message) { }
    }

    public class ValidationException : Exception
    {
        public IDictionary<string, string[]>? Errors { get; }

        public ValidationException(string message) : base(message) { }

        public ValidationException(string message, IDictionary<string, string[]> errors) : base(message)
        {
            Errors = errors;
        }

        public ValidationException(string message, string field, string error) : base(message)
        {
            Errors = new Dictionary<string, string[]>
            {
                [field] = new[] { error }
            };
        }
    }

    public class ForbiddenException : Exception
    {
        public ForbiddenException(string message) : base(message) { }
    }

    public class BusinessException : Exception
    {
        public BusinessException(string message) : base(message) { }
    }

    public class ConflictException : Exception
    {
        public ConflictException(string message) : base(message) { }
    }
}
