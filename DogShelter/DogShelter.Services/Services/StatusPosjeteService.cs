using AutoMapper;
using DogShelter.Model;
using DogShelter.Model.Requests;
using DogShelter.Services.Constants;
using DogShelter.Services.Database;
using DogShelter.Services.Exceptions;
using DogShelter.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;

namespace DogShelter.Services.Services
{
    public class StatusPosjeteService : CRUDService<Model.StatusPosjete, LookupSearchRequest, Database.StatusPosjete, LookupUpsertRequest, LookupUpsertRequest>, IStatusPosjeteService
    {
        private readonly IMemoryCache _cache;
        private const string CacheKey = "status_posjete_all";

        private static readonly HashSet<string> CanonicalNazivi = new(StringComparer.OrdinalIgnoreCase)
        {
            StatusPosjeteNazivi.NaCekanju,
            StatusPosjeteNazivi.Potvrdjena,
            StatusPosjeteNazivi.Otkazana,
            StatusPosjeteNazivi.Zavrsena,
        };

        public StatusPosjeteService(DogShelterContext context, IMapper mapper, IMemoryCache cache) : base(context, mapper)
        {
            _cache = cache;
        }

        private async Task EnsureNotCanonicalAsync(int id)
        {
            var entity = await _context.StatusPosjetes.FindAsync(id);
            if (entity != null && CanonicalNazivi.Contains(entity.Naziv))
            {
                throw new BusinessException("Ovaj status je dio sistemske logike (obrada posjeta) i ne može biti preimenovan niti obrisan.");
            }
        }

        public override async Task<PagedResult<Model.StatusPosjete>> Get(LookupSearchRequest search)
        {
            var all = await GetAllCachedAsync();

            if (!string.IsNullOrWhiteSpace(search.Naziv))
                all = all.Where(x => x.Naziv.Contains(search.Naziv, StringComparison.OrdinalIgnoreCase)).ToList();

            var (page, pageSize) = PaginationHelper.Normalize(search);
            return new PagedResult<Model.StatusPosjete>
            {
                Items = all.Skip((page - 1) * pageSize).Take(pageSize).ToList(),
                TotalCount = all.Count,
                Page = page,
                PageSize = pageSize
            };
        }

        public override async Task<Model.StatusPosjete> Insert(LookupUpsertRequest request) { var r = await base.Insert(request); InvalidateCache(); return r; }
        public override async Task<Model.StatusPosjete> Update(int ID, LookupUpsertRequest request) { await EnsureNotCanonicalAsync(ID); var r = await base.Update(ID, request); InvalidateCache(); return r; }
        public override async Task<bool> Delete(int ID) { await EnsureNotCanonicalAsync(ID); var r = await base.Delete(ID); InvalidateCache(); return r; }

        private async Task<List<Model.StatusPosjete>> GetAllCachedAsync()
        {
            return await _cache.GetOrCreateAsync(CacheKey, async entry =>
            {
                entry.SlidingExpiration = TimeSpan.FromMinutes(10);
                var entities = await _context.StatusPosjetes.AsNoTracking().OrderBy(x => x.Naziv).ToListAsync();
                return _mapper.Map<List<Model.StatusPosjete>>(entities);
            }) ?? [];
        }

        private void InvalidateCache() => _cache.Remove(CacheKey);
    }
}
