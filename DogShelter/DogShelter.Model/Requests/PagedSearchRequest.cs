using System.ComponentModel.DataAnnotations;

namespace DogShelter.Model.Requests
{
    public class PagedSearchRequest
    {
        [Range(1, int.MaxValue, ErrorMessage = ValidationMessages.PageMin)]
        public int Page { get; set; } = 1;

        [Range(1, 100, ErrorMessage = ValidationMessages.PageSizeRange)]
        public int PageSize { get; set; } = 20;
    }
}
