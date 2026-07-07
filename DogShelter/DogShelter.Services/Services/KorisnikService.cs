using AutoMapper;
using DogShelter.Model;
using DogShelter.Model.Requests;
using DogShelter.Services.Database;
using DogShelter.Services.Exceptions;
using DogShelter.Services.Interfaces;
using Microsoft.EntityFrameworkCore;

namespace DogShelter.Services.Services
{
    public class KorisnikService : CRUDService<Model.Korisnik, KorisnikSearchRequest, Database.Korisnik, KorisnikInsertRequest, KorisnikUpdateRequest>,
        IKorisnikService
    {
        public KorisnikService(DogShelterContext context, IMapper mapper) : base(context, mapper) { }

        public override async Task<PagedResult<Model.Korisnik>> Get(KorisnikSearchRequest search)
        {
            var query = _context.Korisniks
                .Include(k => k.KorisnikUlogas).ThenInclude(ku => ku.Uloga)
                .AsQueryable();

            if (!string.IsNullOrWhiteSpace(search.KorisnickoIme))
                query = query.Where(k => k.KorisnickoIme.Contains(search.KorisnickoIme));

            return await ToPagedResultAsync(query, search);
        }

        public override async Task<Model.Korisnik> GetById(int ID)
        {
            var entity = await _context.Korisniks
                .Include(k => k.KorisnikUlogas).ThenInclude(ku => ku.Uloga)
                .FirstOrDefaultAsync(k => k.KorisnikId == ID);
            return _mapper.Map<Model.Korisnik>(entity);
        }

        public override async Task<Model.Korisnik> Insert(KorisnikInsertRequest request)
        {
            if (await _context.Korisniks.AnyAsync(k => k.KorisnickoIme == request.KorisnickoIme))
                throw new BusinessException("Korisničko ime je zauzeto.");
            if (await _context.Korisniks.AnyAsync(k => k.Email == request.Email))
                throw new BusinessException("Email je već u upotrebi.");

            var entity = _mapper.Map<Database.Korisnik>(request);
            entity.LozinkaHash = HashPassword(request.Lozinka);
            entity.LozinkaSalt = string.Empty;
            entity.Aktivan = true;

            _context.Korisniks.Add(entity);
            await _context.SaveChangesAsync();

            if (request.Uloge.Count > 0)
            {
                var roles = await _context.Ulogas
                    .Where(u => request.Uloge.Contains(u.Naziv))
                    .ToListAsync();

                var invalidRoles = request.Uloge.Except(roles.Select(r => r.Naziv)).ToList();
                if (invalidRoles.Count > 0)
                    throw new BusinessException($"Nepostojece uloge: {string.Join(", ", invalidRoles)}");

                foreach (var role in roles)
                {
                    _context.KorisnikUlogas.Add(new Database.KorisnikUloga
                    {
                        KorisnikId = entity.KorisnikId,
                        UlogaId = role.UlogaId
                    });
                }
                await _context.SaveChangesAsync();
            }

            return await GetById(entity.KorisnikId);
        }

        public async Task<Model.Korisnik?> Authenticate(AuthenticationRequest request)
        {
            var user = await _context.Korisniks
                .Include(k => k.KorisnikUlogas).ThenInclude(ku => ku.Uloga)
                .FirstOrDefaultAsync(k => k.KorisnickoIme == request.KorisnickoIme && k.Aktivan);

            if (user == null)
                return null;

            return VerifyPassword(request.Lozinka, user.LozinkaHash)
                ? _mapper.Map<Model.Korisnik>(user)
                : null;
        }

        public async Task<Model.Korisnik> Register(RegisterRequest request)
        {
            if (await _context.Korisniks.AnyAsync(k => k.KorisnickoIme == request.KorisnickoIme))
                throw new BusinessException("Korisničko ime je zauzeto.");
            if (await _context.Korisniks.AnyAsync(k => k.Email == request.Email))
                throw new BusinessException("Email je već u upotrebi.");

            var entity = new Database.Korisnik
            {
                Ime = request.Ime,
                Prezime = request.Prezime,
                Email = request.Email,
                Telefon = request.Telefon,
                KorisnickoIme = request.KorisnickoIme,
                SlikaPutanja = request.SlikaPutanja,
                LozinkaHash = HashPassword(request.Lozinka),
                LozinkaSalt = string.Empty,
                Aktivan = true
            };

            _context.Korisniks.Add(entity);
            await _context.SaveChangesAsync();

            var korisnikRole = await _context.Ulogas.FirstOrDefaultAsync(u => u.Naziv == "Korisnik");
            if (korisnikRole != null)
            {
                _context.KorisnikUlogas.Add(new Database.KorisnikUloga
                {
                    KorisnikId = entity.KorisnikId,
                    UlogaId = korisnikRole.UlogaId
                });
                await _context.SaveChangesAsync();
            }

            return await GetById(entity.KorisnikId);
        }

        public async Task<Model.Korisnik> UpdateMyProfile(int userId, KorisnikProfileUpdateRequest request)
        {
            var entity = await _context.Korisniks.FindAsync(userId)
                ?? throw new NotFoundException("Korisnik nije pronađen.");

            if (await _context.Korisniks.AnyAsync(k => k.KorisnickoIme == request.KorisnickoIme && k.KorisnikId != userId))
                throw new BusinessException("Korisničko ime je zauzeto.");
            if (await _context.Korisniks.AnyAsync(k => k.Email == request.Email && k.KorisnikId != userId))
                throw new BusinessException("Email je već u upotrebi.");

            entity.Ime = request.Ime;
            entity.Prezime = request.Prezime;
            entity.Email = request.Email;
            entity.Telefon = request.Telefon;
            entity.KorisnickoIme = request.KorisnickoIme;
            if (!string.IsNullOrEmpty(request.SlikaPutanja))
                entity.SlikaPutanja = request.SlikaPutanja;

            await _context.SaveChangesAsync();
            return await GetById(userId);
        }

        public static string HashPassword(string password)
            => BCrypt.Net.BCrypt.HashPassword(password, workFactor: 12);

        public static bool VerifyPassword(string password, string hash)
            => BCrypt.Net.BCrypt.Verify(password, hash);
    }
}
