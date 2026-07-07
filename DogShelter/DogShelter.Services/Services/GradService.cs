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
    public class GradService : CRUDService<Model.Grad, GradSearchRequest, Database.Grad, GradUpsertRequest, GradUpsertRequest>, IGradService
    {
        private readonly IMemoryCache _cache;
        private const string CacheKey = "grad_all";

        public GradService(DogShelterContext context, IMapper mapper, IMemoryCache cache) : base(context, mapper)
        {
            _cache = cache;
        }

        public override async Task<PagedResult<Model.Grad>> Get(GradSearchRequest search)
        {
            var all = await GetAllCachedAsync();

            if (!string.IsNullOrWhiteSpace(search.Naziv))
                all = all.Where(g => g.Naziv.Contains(search.Naziv, StringComparison.OrdinalIgnoreCase)).ToList();

            if (!string.IsNullOrWhiteSpace(search.PostanskiBroj))
                all = all.Where(g => g.PostanskiBroj.Contains(search.PostanskiBroj, StringComparison.OrdinalIgnoreCase)).ToList();

            var (page, pageSize) = PaginationHelper.Normalize(search);
            return new PagedResult<Model.Grad>
            {
                Items = all.Skip((page - 1) * pageSize).Take(pageSize).ToList(),
                TotalCount = all.Count,
                Page = page,
                PageSize = pageSize
            };
        }

        public override async Task<Model.Grad> Insert(GradUpsertRequest request)
        {
            if (await _context.Grads.AnyAsync(g => g.Naziv == request.Naziv))
                throw new ConflictException("Grad s tim nazivom već postoji.");

            var result = await base.Insert(request);
            InvalidateCache();
            return result;
        }

        public override async Task<Model.Grad> Update(int ID, GradUpsertRequest request)
        {
            if (await _context.Grads.AnyAsync(g => g.Naziv == request.Naziv && g.GradId != ID))
                throw new ConflictException("Grad s tim nazivom već postoji.");

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

        private async Task<List<Model.Grad>> GetAllCachedAsync()
        {
            return await _cache.GetOrCreateAsync(CacheKey, async entry =>
            {
                entry.SlidingExpiration = TimeSpan.FromMinutes(10);
                var entities = await _context.Grads.AsNoTracking().OrderBy(g => g.Naziv).ToListAsync();
                return _mapper.Map<List<Model.Grad>>(entities);
            }) ?? [];
        }

        private void InvalidateCache() => _cache.Remove(CacheKey);
    }
}
