using AutoMapper;
using DogShelter.Model;
using DogShelter.Model.Requests;
using DogShelter.Services.Database;
using DogShelter.Services.Exceptions;
using DogShelter.Services.Interfaces;
using Microsoft.EntityFrameworkCore;
using Microsoft.Extensions.Caching.Memory;

namespace DogShelter.Services.Services
{
    public class UlogaService : CRUDService<Model.Uloga, LookupSearchRequest, Database.Uloga, LookupUpsertRequest, LookupUpsertRequest>, IUlogaService
    {
        private readonly IMemoryCache _cache;
        private const string CacheKey = "uloga_all";

        private static readonly HashSet<string> CanonicalNazivi = new(StringComparer.OrdinalIgnoreCase)
        {
            RoleNames.Admin,
            RoleNames.Volonter,
            RoleNames.Korisnik,
        };

        public UlogaService(DogShelterContext context, IMapper mapper, IMemoryCache cache) : base(context, mapper)
        {
            _cache = cache;
        }

        private async Task EnsureNotCanonicalAsync(int id)
        {
            var entity = await _context.Ulogas.FindAsync(id);
            if (entity != null && CanonicalNazivi.Contains(entity.Naziv))
            {
                throw new BusinessException("Ova uloga je dio sistemske logike (autorizacija korisnika) i ne može biti preimenovana niti obrisana.");
            }
        }

        public override async Task<PagedResult<Model.Uloga>> Get(LookupSearchRequest search)
        {
            var all = await GetAllCachedAsync();

            if (!string.IsNullOrWhiteSpace(search.Naziv))
                all = all.Where(x => x.Naziv.Contains(search.Naziv, StringComparison.OrdinalIgnoreCase)).ToList();

            var (page, pageSize) = PaginationHelper.Normalize(search);
            return new PagedResult<Model.Uloga>
            {
                Items = all.Skip((page - 1) * pageSize).Take(pageSize).ToList(),
                TotalCount = all.Count,
                Page = page,
                PageSize = pageSize
            };
        }

        public override async Task<Model.Uloga> Insert(LookupUpsertRequest request) { var r = await base.Insert(request); InvalidateCache(); return r; }
        public override async Task<Model.Uloga> Update(int ID, LookupUpsertRequest request) { await EnsureNotCanonicalAsync(ID); var r = await base.Update(ID, request); InvalidateCache(); return r; }
        public override async Task<bool> Delete(int ID) { await EnsureNotCanonicalAsync(ID); var r = await base.Delete(ID); InvalidateCache(); return r; }

        private async Task<List<Model.Uloga>> GetAllCachedAsync()
        {
            return await _cache.GetOrCreateAsync(CacheKey, async entry =>
            {
                entry.SlidingExpiration = TimeSpan.FromMinutes(10);
                var entities = await _context.Ulogas.AsNoTracking().OrderBy(x => x.Naziv).ToListAsync();
                return _mapper.Map<List<Model.Uloga>>(entities);
            }) ?? [];
        }

        private void InvalidateCache() => _cache.Remove(CacheKey);
    }
}
