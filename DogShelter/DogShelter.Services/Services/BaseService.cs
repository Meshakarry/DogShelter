using DogShelter.Model;
using AutoMapper;
using DogShelter.Model.Requests;
using DogShelter.Services.Database;
using DogShelter.Services.Exceptions;
using DogShelter.Services.Interfaces;

namespace DogShelter.Services.Services
{
    public class BaseService<TModel, TSearch, TDatabase> : IBaseService<TModel, TSearch>
        where TDatabase : class
        where TSearch : PagedSearchRequest
    {
        protected DogShelterContext _context;
        protected IMapper _mapper;

        public BaseService(DogShelterContext context, IMapper mapper)
        {
            _context = context;
            _mapper = mapper;
        }

        public virtual async Task<PagedResult<TModel>> Get(TSearch search)
        {
            IQueryable<TDatabase> query = _context.Set<TDatabase>();
            return await ToPagedResultAsync(query, search);
        }

        protected Task<PagedResult<TModel>> ToPagedResultAsync(IQueryable<TDatabase> query, PagedSearchRequest? search) =>
            PagedQueryHelper.ToPagedResultAsync<TDatabase, TModel>(query, search, _mapper);

        public virtual async Task<TModel> GetById(int ID)
        {
            var entity = await _context.Set<TDatabase>().FindAsync(ID)
                ?? throw new NotFoundException($"{typeof(TDatabase).Name} s ID {ID} nije pronađen(a).");
            return _mapper.Map<TModel>(entity);
        }
    }
}
