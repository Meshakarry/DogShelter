using AutoMapper;
using DogShelter.Model;
using DogShelter.Model.Requests;
using DogShelter.Services.Database;
using DogShelter.Services.Exceptions;
using DogShelter.Services.Interfaces;
using Microsoft.AspNetCore.Http;
using Microsoft.EntityFrameworkCore;

namespace DogShelter.Services.Services
{
    public class KorisnikService : CRUDService<Model.Korisnik, KorisnikSearchRequest, Database.Korisnik, KorisnikInsertRequest, KorisnikUpdateRequest>,
        IKorisnikService
    {
        private readonly IFileUploadService _fileUpload;

        public KorisnikService(DogShelterContext context, IMapper mapper, IFileUploadService fileUpload) : base(context, mapper)
        {
            _fileUpload = fileUpload;
        }

        public override async Task<PagedResult<Model.Korisnik>> Get(KorisnikSearchRequest search)
        {
            var query = _context.Korisniks
                .Include(k => k.KorisnikUlogas).ThenInclude(ku => ku.Uloga)
                .AsQueryable();

            if (!string.IsNullOrWhiteSpace(search.KorisnickoIme))
                query = query.Where(k => k.KorisnickoIme.Contains(search.KorisnickoIme));

            if (search.UlogaId.HasValue)
                query = query.Where(k => k.KorisnikUlogas.Any(ku => ku.UlogaId == search.UlogaId.Value));

            if (search.Aktivan.HasValue)
                query = query.Where(k => k.Aktivan == search.Aktivan.Value);

            query = query.OrderByDescending(k => k.DatumRegistracije);

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

            EnsureNoDirectVolonterRoleChange(request.Uloge, []);

            await using var tx = await _context.Database.BeginTransactionAsync();
            try
            {
                var entity = _mapper.Map<Database.Korisnik>(request);
                entity.LozinkaHash = HashPassword(request.Lozinka);
                entity.LozinkaSalt = string.Empty;
                entity.Aktivan = true;

                _context.Korisniks.Add(entity);
                await _context.SaveChangesAsync();

                if (request.Uloge.Count > 0)
                {
                    var roles = await ResolveRoleIdsByNamesAsync(request.Uloge);
                    foreach (var roleId in roles)
                    {
                        _context.KorisnikUlogas.Add(new Database.KorisnikUloga
                        {
                            KorisnikId = entity.KorisnikId,
                            UlogaId = roleId
                        });
                    }
                    await _context.SaveChangesAsync();
                }

                await tx.CommitAsync();
                return await GetById(entity.KorisnikId);
            }
            catch
            {
                await tx.RollbackAsync();
                throw;
            }
        }

        public override async Task<Model.Korisnik> Update(int ID, KorisnikUpdateRequest request)
        {
            var entity = await _context.Korisniks.FindAsync(ID)
                ?? throw new NotFoundException("Korisnik nije pronađen.");

            if (!string.IsNullOrWhiteSpace(request.KorisnickoIme) &&
                await _context.Korisniks.AnyAsync(k => k.KorisnickoIme == request.KorisnickoIme && k.KorisnikId != ID))
                throw new BusinessException("Korisničko ime je zauzeto.");

            if (!string.IsNullOrWhiteSpace(request.Email) &&
                await _context.Korisniks.AnyAsync(k => k.Email == request.Email && k.KorisnikId != ID))
                throw new BusinessException("Email je već u upotrebi.");

            if (request.GradId.HasValue && !await _context.Grads.AnyAsync(g => g.GradId == request.GradId.Value))
                throw new ValidationException("Odabrani grad ne postoji.", nameof(request.GradId), "Grad ne postoji.");

            EnsureNoDirectVolonterRoleChange(request.Uloge, request.UlogeZaBrisanje);

            // A deactivated account can't log in (Authenticate filters on Aktivan) and any token
            // it already holds is rejected too (OnTokenValidated re-checks Aktivan), so granting
            // it a role isn't an active access risk - but it's a confusing state to leave lying
            // around ("why does this disabled account have Admin"). Adding roles is only allowed
            // when the account will actually be active once this request applies - reactivating
            // and assigning a role in the same call is still fine. Removing roles is always fine.
            var resultingAktivan = request.Status ?? entity.Aktivan;
            if (!resultingAktivan && request.Uloge.Count > 0)
                throw new BusinessException("Ne možete dodijeliti ulogu neaktivnom korisniku. Prvo reaktivirajte nalog.");

            // Any of these three invalidate previously issued tokens (see Program.cs
            // OnTokenValidated) - a stale token must not keep working with a stale password, a
            // role it no longer holds, or on an account that just got deactivated.
            var securityRelevantChange = !string.IsNullOrWhiteSpace(request.Lozinka)
                || request.Uloge.Count > 0
                || request.UlogeZaBrisanje.Count > 0
                || (request.Status.HasValue && request.Status.Value != entity.Aktivan);

            // Length and confirmation-match are already enforced by KorisnikUpdateRequest's
            // MinLength/Compare attributes (checked by [ApiController] before this method ever
            // runs) - the same rules Register/Insert apply, just via the same route on this DTO.
            if (!string.IsNullOrWhiteSpace(request.Lozinka))
            {
                entity.LozinkaHash = HashPassword(request.Lozinka);
                entity.LozinkaSalt = string.Empty;
            }

            await using var tx = await _context.Database.BeginTransactionAsync();
            try
            {
                entity.Ime = request.Ime;
                entity.Prezime = request.Prezime;
                if (!string.IsNullOrWhiteSpace(request.Email)) entity.Email = request.Email;
                if (!string.IsNullOrWhiteSpace(request.KorisnickoIme)) entity.KorisnickoIme = request.KorisnickoIme;
                if (request.Telefon != null) entity.Telefon = request.Telefon;
                if (request.GradId.HasValue) entity.GradId = request.GradId;
                if (request.Adresa != null) entity.Adresa = request.Adresa;
                if (request.Status.HasValue) entity.Aktivan = request.Status.Value;
                if (securityRelevantChange) entity.SigurnosniPecat = Guid.NewGuid();

                await _context.SaveChangesAsync();

                if (request.Uloge.Count > 0)
                {
                    foreach (var roleId in await ResolveRoleIdsByNamesAsync(request.Uloge))
                    {
                        var exists = await _context.KorisnikUlogas
                            .AnyAsync(ku => ku.KorisnikId == ID && ku.UlogaId == roleId);
                        if (!exists)
                            _context.KorisnikUlogas.Add(new Database.KorisnikUloga { KorisnikId = ID, UlogaId = roleId });
                    }
                    await _context.SaveChangesAsync();
                }

                if (request.UlogeZaBrisanje.Count > 0)
                {
                    foreach (var roleId in await ResolveRoleIdsByNamesAsync(request.UlogeZaBrisanje))
                    {
                        var ku = await _context.KorisnikUlogas
                            .FirstOrDefaultAsync(x => x.KorisnikId == ID && x.UlogaId == roleId);
                        if (ku != null)
                            _context.KorisnikUlogas.Remove(ku);
                    }
                    await _context.SaveChangesAsync();
                }

                await tx.CommitAsync();
                return await GetById(ID);
            }
            catch
            {
                await tx.RollbackAsync();
                throw;
            }
        }

        public override async Task<bool> Delete(int ID)
        {
            var entity = await _context.Korisniks.FindAsync(ID)
                ?? throw new NotFoundException("Korisnik nije pronađen.");

            await using var tx = await _context.Database.BeginTransactionAsync();
            try
            {
                var roles = await _context.KorisnikUlogas.Where(ku => ku.KorisnikId == ID).ToListAsync();
                _context.KorisnikUlogas.RemoveRange(roles);

                entity.Ime = "Obrisani";
                entity.Prezime = "Korisnik";
                entity.Email = $"obrisani_{ID}@invalid.local";
                entity.KorisnickoIme = $"obrisani_{ID}";
                entity.Telefon = null;
                entity.Adresa = null;
                entity.SlikaPutanja = null;
                entity.LozinkaHash = string.Empty;
                entity.LozinkaSalt = string.Empty;
                entity.Aktivan = false;
                entity.SigurnosniPecat = Guid.NewGuid();

                await _context.SaveChangesAsync();
                await tx.CommitAsync();
                return true;
            }
            catch
            {
                await tx.RollbackAsync();
                throw;
            }
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

            await using var tx = await _context.Database.BeginTransactionAsync();
            try
            {
                var entity = new Database.Korisnik
                {
                    Ime = request.Ime,
                    Prezime = request.Prezime,
                    Email = request.Email,
                    Telefon = request.Telefon,
                    KorisnickoIme = request.KorisnickoIme,
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

                await tx.CommitAsync();
                return await GetById(entity.KorisnikId);
            }
            catch
            {
                await tx.RollbackAsync();
                throw;
            }
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

            await _context.SaveChangesAsync();
            return await GetById(userId);
        }

        public async Task ChangeMyPassword(int userId, KorisnikChangePasswordRequest request)
        {
            var entity = await _context.Korisniks.FindAsync(userId)
                ?? throw new NotFoundException("Korisnik nije pronađen.");

            if (!VerifyPassword(request.StaraLozinka, entity.LozinkaHash))
                throw new ValidationException(ValidationMessages.OldPasswordIncorrect,
                    nameof(request.StaraLozinka), ValidationMessages.OldPasswordIncorrect);

            entity.LozinkaHash = HashPassword(request.NovaLozinka);
            entity.LozinkaSalt = string.Empty;
            entity.SigurnosniPecat = Guid.NewGuid();
            await _context.SaveChangesAsync();
        }

        public async Task<Model.Korisnik> UpdateMyAvatar(int userId, IFormFile file)
        {
            var entity = await _context.Korisniks.FindAsync(userId)
                ?? throw new NotFoundException("Korisnik nije pronađen.");

            var oldPath = entity.SlikaPutanja;
            entity.SlikaPutanja = await _fileUpload.SavePrivateImageAsync(file, "korisnici");
            await _context.SaveChangesAsync();

            _fileUpload.DeletePrivateImage(oldPath);

            return await GetById(userId);
        }

        public async Task<(string FullPath, string ContentType)> GetAvatarFileAsync(int id, int callerId, bool isAdmin)
        {
            if (!isAdmin && id != callerId)
                throw new ForbiddenException("Nemate pristup ovoj slici.");

            var entity = await _context.Korisniks.FindAsync(id)
                ?? throw new NotFoundException("Korisnik nije pronađen.");

            var fullPath = _fileUpload.GetPrivateFilePath(entity.SlikaPutanja)
                ?? throw new NotFoundException("Korisnik nema postavljenu sliku.");

            return (fullPath, _fileUpload.GetContentType(fullPath));
        }

        // The generic Uloge/UlogeZaBrisanje lists let an admin assign or remove ANY role by name -
        // including "Volonter", bypassing the profile<->role sync VolonterService.Update()
        // maintains. Blocking it here entirely keeps VolonterService the single place that
        // mutates that role, instead of re-checking Volonter.Aktivan in two places.
        private static void EnsureNoDirectVolonterRoleChange(IEnumerable<string> uloge, IEnumerable<string> ulogeZaBrisanje)
        {
            var touchesVolonter = uloge.Any(u => string.Equals(u, RoleNames.Volonter, StringComparison.OrdinalIgnoreCase))
                || ulogeZaBrisanje.Any(u => string.Equals(u, RoleNames.Volonter, StringComparison.OrdinalIgnoreCase));

            if (touchesVolonter)
                throw new BusinessException(
                    "Uloga 'Volonter' se ne može dodijeliti niti ukloniti odavde. Upravljajte volonterskim statusom kroz sekciju Volonteri (kreiranje/aktivacija/deaktivacija profila).");
        }

        public static string HashPassword(string password)
            => BCrypt.Net.BCrypt.HashPassword(password, workFactor: 12);

        public static bool VerifyPassword(string password, string hash)
            => BCrypt.Net.BCrypt.Verify(password, hash);

        private async Task<List<int>> ResolveRoleIdsByNamesAsync(IEnumerable<string> roleNames)
        {
            var names = roleNames
                .Where(n => !string.IsNullOrWhiteSpace(n))
                .Select(n => n.Trim())
                .Distinct(StringComparer.OrdinalIgnoreCase)
                .ToList();

            if (names.Count == 0)
                return new List<int>();

            var allRoles = await _context.Ulogas.AsNoTracking().ToListAsync();
            var roleIds = new List<int>();

            foreach (var name in names)
            {
                var role = allRoles.FirstOrDefault(r =>
                    string.Equals(r.Naziv, name, StringComparison.OrdinalIgnoreCase));

                if (role == null)
                    throw new BusinessException($"Uloga '{name}' ne postoji.");

                roleIds.Add(role.UlogaId);
            }

            return roleIds;
        }
    }
}
