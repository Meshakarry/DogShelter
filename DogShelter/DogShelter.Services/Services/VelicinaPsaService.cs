using AutoMapper;
using DogShelter.Model;
using DogShelter.Model.Requests;
using DogShelter.Services.Database;
using DogShelter.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;

namespace DogShelter.Services.Services
{
    public class VelicinaPsaService : CRUDService<Model.VelicinaPsa, LookupSearchRequest, Database.VelicinaPsa, LookupUpsertRequest, LookupUpsertRequest>, IVelicinaPsaService
    {
        private readonly IMemoryCache _cache;
        private const string CacheKey = "velicina_psa_all";

        public VelicinaPsaService(DogShelterContext context, IMapper mapper, IMemoryCache cache) : base(context, mapper)
        {
            _cache = cache;
        }

        public override async Task<PagedResult<Model.VelicinaPsa>> Get(LookupSearchRequest search)
        {
            var all = await GetAllCachedAsync();

            if (!string.IsNullOrWhiteSpace(search.Naziv))
                all = all.Where(x => x.Naziv.Contains(search.Naziv, StringComparison.OrdinalIgnoreCase)).ToList();

            var (page, pageSize) = PaginationHelper.Normalize(search);
            return new PagedResult<Model.VelicinaPsa>
            {
                Items = all.Skip((page - 1) * pageSize).Take(pageSize).ToList(),
                TotalCount = all.Count,
                Page = page,
                PageSize = pageSize
            };
        }

        public override async Task<Model.VelicinaPsa> Insert(LookupUpsertRequest request) { var r = await base.Insert(request); InvalidateCache(); return r; }
        public override async Task<Model.VelicinaPsa> Update(int ID, LookupUpsertRequest request) { var r = await base.Update(ID, request); InvalidateCache(); return r; }
        public override async Task<bool> Delete(int ID) { var r = await base.Delete(ID); InvalidateCache(); return r; }

        private async Task<List<Model.VelicinaPsa>> GetAllCachedAsync()
        {
            return await _cache.GetOrCreateAsync(CacheKey, async entry =>
            {
                entry.SlidingExpiration = TimeSpan.FromMinutes(10);
                var entities = await _context.VelicinaPsas.AsNoTracking().OrderBy(x => x.Naziv).ToListAsync();
                return _mapper.Map<List<Model.VelicinaPsa>>(entities);
            }) ?? [];
        }

        private void InvalidateCache() => _cache.Remove(CacheKey);
    }
}
