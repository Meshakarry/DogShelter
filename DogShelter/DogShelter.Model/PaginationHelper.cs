using DogShelter.Model.Requests;

namespace DogShelter.Model
{
    public static class PaginationHelper
    {
        public const int DefaultPage = 1;
        public const int DefaultPageSize = 20;
        public const int MaxPageSize = 100;

        public static (int page, int pageSize) Normalize(PagedSearchRequest? search)
        {
            var page = search?.Page ?? DefaultPage;
            var pageSize = search?.PageSize ?? DefaultPageSize;

            if (page < 1)
                page = DefaultPage;

            pageSize = Math.Clamp(pageSize, 1, MaxPageSize);
            return (page, pageSize);
        }
    }
}
