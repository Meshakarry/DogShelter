using AutoMapper;
using DogShelter.Model;
using DogShelter.Model.Requests;
using Microsoft.EntityFrameworkCore;

namespace DogShelter.Services
{
    public static class PagedQueryHelper
    {
        public static async Task<PagedResult<TModel>> ToPagedResultAsync<TEntity, TModel>(
            IQueryable<TEntity> query,
            PagedSearchRequest? search,
            IMapper mapper) where TEntity : class
        {
            var (page, pageSize) = PaginationHelper.Normalize(search);
            var totalCount = await query.CountAsync();
            var entities = await query
                .Skip((page - 1) * pageSize)
                .Take(pageSize)
                .ToListAsync();

            return new PagedResult<TModel>
            {
                Items = mapper.Map<List<TModel>>(entities),
                TotalCount = totalCount,
                Page = page,
                PageSize = pageSize
            };
        }
    }
}
