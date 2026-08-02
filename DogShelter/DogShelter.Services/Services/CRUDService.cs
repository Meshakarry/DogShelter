using AutoMapper;
using DogShelter.Model.Requests;
using DogShelter.Services.Database;
using DogShelter.Services.Exceptions;
using DogShelter.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DogShelter.Services.Services
{
    public class CRUDService<TModel, TSearch, TDatabase, TInsert, TUpdate> : BaseService<TModel, TSearch, TDatabase>,
        ICRUDService<TModel, TSearch, TInsert, TUpdate>
        where TDatabase : class
        where TSearch : PagedSearchRequest
    {
        private new readonly DogShelterContext _context;
        private new readonly IMapper _mapper;
        public CRUDService(DogShelterContext context, IMapper mapper) : base(context, mapper)
        {
            _context = context;
            _mapper = mapper;
        }

        public virtual async Task<TModel> Insert(TInsert request)
        {
            var entity = _mapper.Map<TDatabase>(request);
            _context.Set<TDatabase>().Add(entity);
            await _context.SaveChangesAsync();

            return _mapper.Map<TModel>(entity);
        }

        public virtual async Task<TModel> Update(int ID, TUpdate request)
        {
            var entity = await _context.Set<TDatabase>().FindAsync(ID);
            if (entity == null)
                throw new NotFoundException($"Entity with ID {ID} not found.");
            _context.Set<TDatabase>().Attach(entity);
            _context.Set<TDatabase>().Update(entity);

            _mapper.Map(request, entity);

            await _context.SaveChangesAsync();

            return _mapper.Map<TModel>(entity);
        }

        public virtual async Task<bool> Delete(int ID)
        {
            var entity = await _context.Set<TDatabase>().FindAsync(ID);
            if (entity == null)
                throw new NotFoundException($"Entity with ID {ID} not found.");
            try
            {
                _context.Set<TDatabase>().Remove(entity);
                await _context.SaveChangesAsync();
                return true;
            }
            catch (DbUpdateException ex)
            {
                DbUpdateExceptionMapper.ThrowDeleteConflictOrRethrow(ex);
                throw;
            }
        }
    }
}
