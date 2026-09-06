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
    public class KategorijaDonacijeService : CRUDService<Model.KategorijaDonacije, LookupSearchRequest, Database.KategorijaDonacije, KategorijaDonacijeUpsertRequest, KategorijaDonacijeUpsertRequest>, IKategorijaDonacijeService
    {
        private readonly IMemoryCache _cache;
        private const string CacheKey = "kategorija_donacije_all";

        public KategorijaDonacijeService(DogShelterContext context, IMapper mapper, IMemoryCache cache) : base(context, mapper)
        {
            _cache = cache;
        }

        public override async Task<PagedResult<Model.KategorijaDonacije>> Get(LookupSearchRequest search)
        {
            var all = await GetAllCachedAsync();

            if (!string.IsNullOrWhiteSpace(search.Naziv))
                all = all.Where(x => x.Naziv.Contains(search.Naziv, StringComparison.OrdinalIgnoreCase)).ToList();

            var (page, pageSize) = PaginationHelper.Normalize(search);
            return new PagedResult<Model.KategorijaDonacije>
            {
                Items = all.Skip((page - 1) * pageSize).Take(pageSize).ToList(),
                TotalCount = all.Count,
                Page = page,
                PageSize = pageSize
            };
        }

        public override async Task<Model.KategorijaDonacije> Insert(KategorijaDonacijeUpsertRequest request)
        {
            var entity = _mapper.Map<Database.KategorijaDonacije>(request);
            entity.DozvoljeneJedinice = await ResolveDozvoljeneJediniceAsync(request);
            _context.KategorijaDonacijes.Add(entity);
            await _context.SaveChangesAsync();
            InvalidateCache();
            return _mapper.Map<Model.KategorijaDonacije>(entity);
        }

        public override async Task<Model.KategorijaDonacije> Update(int ID, KategorijaDonacijeUpsertRequest request)
        {
            var entity = await _context.KategorijaDonacijes.Include(k => k.DozvoljeneJedinice).FirstOrDefaultAsync(k => k.KategorijaDonacijeId == ID)
                ?? throw new NotFoundException($"Entity with ID {ID} not found.");

            // "Ostalo" is looked up by exact name in DonacijaService (the free-text
            // PrilagodjenNaziv field is only allowed for that one category) - renaming it would
            // silently break that check for every future donation, not just this row. Other
            // fields (icon, allowed units, ...) can still be edited freely.
            if (string.Equals(entity.Naziv, KategorijaDonacijeNazivi.Ostalo, StringComparison.OrdinalIgnoreCase) &&
                !string.Equals(request.Naziv, KategorijaDonacijeNazivi.Ostalo, StringComparison.OrdinalIgnoreCase))
            {
                throw new BusinessException("Kategorija 'Ostalo' je dio sistemske logike (donacije sa slobodnim nazivom) i ne može biti preimenovana.");
            }

            _mapper.Map(request, entity);
            entity.DozvoljeneJedinice = await ResolveDozvoljeneJediniceAsync(request);
            await _context.SaveChangesAsync();
            InvalidateCache();
            return _mapper.Map<Model.KategorijaDonacije>(entity);
        }

        public override async Task<bool> Delete(int ID)
        {
            var entity = await _context.KategorijaDonacijes.FindAsync(ID);
            if (entity != null && string.Equals(entity.Naziv, KategorijaDonacijeNazivi.Ostalo, StringComparison.OrdinalIgnoreCase))
                throw new BusinessException("Kategorija 'Ostalo' je dio sistemske logike (donacije sa slobodnim nazivom) i ne može biti obrisana.");

            var r = await base.Delete(ID);
            InvalidateCache();
            return r;
        }

        private async Task<List<Database.JedinicaMjere>> ResolveDozvoljeneJediniceAsync(KategorijaDonacijeUpsertRequest request)
        {
            if (request.DozvoljeneJediniceIds == null || request.DozvoljeneJediniceIds.Count == 0)
                return [];

            var jedinice = await _context.JedinicaMjeres.Where(j => request.DozvoljeneJediniceIds.Contains(j.JedinicaMjereId)).ToListAsync();
            if (jedinice.Count != request.DozvoljeneJediniceIds.Distinct().Count())
                throw new ValidationException("Jedna ili više odabranih jedinica mjere ne postoji.");

            if (request.PodrazumijevanaJedinicaMjereId.HasValue && !request.DozvoljeneJediniceIds.Contains(request.PodrazumijevanaJedinicaMjereId.Value))
                throw new ValidationException("Podrazumijevana jedinica mjere mora biti jedna od dozvoljenih jedinica.");

            return jedinice;
        }

        private async Task<List<Model.KategorijaDonacije>> GetAllCachedAsync()
        {
            return await _cache.GetOrCreateAsync(CacheKey, async entry =>
            {
                entry.SlidingExpiration = TimeSpan.FromMinutes(10);
                var entities = await _context.KategorijaDonacijes.AsNoTracking()
                    .Include(k => k.DozvoljeneJedinice)
                    .OrderBy(x => x.Naziv)
                    .ToListAsync();
                return _mapper.Map<List<Model.KategorijaDonacije>>(entities);
            }) ?? [];
        }

        private void InvalidateCache() => _cache.Remove(CacheKey);
    }
}
