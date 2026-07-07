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
    public class RasaService : CRUDService<Model.Rasa, RasaSearchRequest, Database.Rasa, RasaUpsertRequest, RasaUpsertRequest>, IRasaService
    {
        private readonly IMemoryCache _cache;
        private const string CacheKey = "rasa_all";

        public RasaService(DogShelterContext context, IMapper mapper, IMemoryCache cache) : base(context, mapper)
        {
            _cache = cache;
        }

        public override async Task<PagedResult<Model.Rasa>> Get(RasaSearchRequest search)
        {
            var all = await GetAllCachedAsync();

            if (!string.IsNullOrWhiteSpace(search.Naziv))
                all = all.Where(r => r.Naziv.Contains(search.Naziv, StringComparison.OrdinalIgnoreCase)).ToList();

            if (search.Aktivan.HasValue)
                all = all.Where(r => r.Aktivan == search.Aktivan.Value).ToList();

            var (page, pageSize) = PaginationHelper.Normalize(search);
            return new PagedResult<Model.Rasa>
            {
                Items = all.Skip((page - 1) * pageSize).Take(pageSize).ToList(),
                TotalCount = all.Count,
                Page = page,
                PageSize = pageSize
            };
        }

        public override async Task<Model.Rasa> Insert(RasaUpsertRequest request)
        {
            if (await _context.Rasas.AnyAsync(r => r.Naziv == request.Naziv))
                throw new ConflictException("Rasa s tim nazivom već postoji.");

            var result = await base.Insert(request);
            InvalidateCache();
            return result;
        }

        public override async Task<Model.Rasa> Update(int ID, RasaUpsertRequest request)
        {
            if (await _context.Rasas.AnyAsync(r => r.Naziv == request.Naziv && r.RasaId != ID))
                throw new ConflictException("Rasa s tim nazivom već postoji.");

            var result = await base.Update(ID, request);
            InvalidateCache();
            return result;
        }

        public override async Task<bool> Delete(int ID)
        {
            var result = await base.Delete(ID);
            InvalidateCache();
            return result;
        }

        private async Task<List<Model.Rasa>> GetAllCachedAsync()
        {
            return await _cache.GetOrCreateAsync(CacheKey, async entry =>
            {
                entry.SlidingExpiration = TimeSpan.FromMinutes(10);
                var entities = await _context.Rasas.AsNoTracking().OrderBy(r => r.Naziv).ToListAsync();
                return _mapper.Map<List<Model.Rasa>>(entities);
            }) ?? [];
        }

        private void InvalidateCache() => _cache.Remove(CacheKey);
    }
}
