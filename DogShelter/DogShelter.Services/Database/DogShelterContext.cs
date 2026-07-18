using Microsoft.EntityFrameworkCore;

namespace DogShelter.Services.Database;

public partial class DogShelterContext : DbContext
{
    public DogShelterContext()
    {
    }

    public DogShelterContext(DbContextOptions<DogShelterContext> options)
        : base(options)
    {
    }

    public virtual DbSet<AktivnostVolontera> AktivnostVolonteras { get; set; }

    public virtual DbSet<Dogadjaj> Dogadjajs { get; set; }

    public virtual DbSet<DogadjajVolonter> DogadjajVolonters { get; set; }

    public virtual DbSet<Donacija> Donacijas { get; set; }

    public virtual DbSet<Grad> Grads { get; set; }

    public virtual DbSet<Korisnik> Korisniks { get; set; }

    public virtual DbSet<KorisnikUloga> KorisnikUlogas { get; set; }

    public virtual DbSet<LozinkaResetToken> LozinkaResetTokens { get; set; }

    public virtual DbSet<Notifikacija> Notifikacijas { get; set; }

    public virtual DbSet<Obavijest> Obavijests { get; set; }

    public virtual DbSet<Pas> Pas { get; set; }

    public virtual DbSet<Posjeta> Posjeta { get; set; }

    public virtual DbSet<PregledPsa> PregledPsas { get; set; }

    public virtual DbSet<Rasa> Rasas { get; set; }

    public virtual DbSet<SlikaPsa> SlikaPsas { get; set; }

    public virtual DbSet<StatusDonacije> StatusDonacijes { get; set; }

    public virtual DbSet<StatusPosjete> StatusPosjetes { get; set; }

    public virtual DbSet<StatusPsa> StatusPsas { get; set; }

    public virtual DbSet<StatusZahtjeva> StatusZahtjevas { get; set; }

    public virtual DbSet<TipAktivnosti> TipAktivnostis { get; set; }

    public virtual DbSet<TipDonacije> TipDonacijes { get; set; }

    public virtual DbSet<Udomljavanje> Udomljavanjes { get; set; }

    public virtual DbSet<Uloga> Ulogas { get; set; }

    public virtual DbSet<VelicinaPsa> VelicinaPsas { get; set; }

    public virtual DbSet<Volonter> Volonters { get; set; }

    public virtual DbSet<ZahtjevZaUdomljavanje> ZahtjevZaUdomljavanjes { get; set; }

    protected override void OnConfiguring(DbContextOptionsBuilder optionsBuilder)
    {
        if (!optionsBuilder.IsConfigured)
            optionsBuilder.UseSqlServer("Server=localhost;Database=180026;Trusted_Connection=True;TrustServerCertificate=True");
    }

    protected override void OnModelCreating(ModelBuilder modelBuilder)
    {
        modelBuilder.Entity<AktivnostVolontera>(entity =>
        {
            entity.ToTable("AktivnostVolontera");

            entity.Property(e => e.BrojSati).HasColumnType("decimal(5, 2)");
            entity.Property(e => e.Opis).HasMaxLength(1000);

            entity.HasOne(d => d.TipAktivnosti).WithMany(p => p.AktivnostVolonteras)
                .HasForeignKey(d => d.TipAktivnostiId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_AktivnostVolontera_Tip");

            entity.HasOne(d => d.Volonter).WithMany(p => p.AktivnostVolonteras)
                .HasForeignKey(d => d.VolonterId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_AktivnostVolontera_Volonter");
        });

        modelBuilder.Entity<Dogadjaj>(entity =>
        {
            entity.ToTable("Dogadjaj");

            entity.Property(e => e.Aktivan).HasDefaultValue(true);
            entity.Property(e => e.Lokacija).HasMaxLength(200);
            entity.Property(e => e.Naziv).HasMaxLength(150);
            entity.Property(e => e.SlikaPutanja).HasMaxLength(500);
        });

        modelBuilder.Entity<DogadjajVolonter>(entity =>
        {
            entity.ToTable("DogadjajVolonter");

            entity.HasIndex(e => new { e.DogadjajId, e.VolonterId }, "UQ_DogadjajVolonter").IsUnique();

            entity.HasOne(d => d.Dogadjaj).WithMany(p => p.DogadjajVolonters)
                .HasForeignKey(d => d.DogadjajId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_DogadjajVolonter_Dogadjaj");

            entity.HasOne(d => d.Volonter).WithMany(p => p.DogadjajVolonters)
                .HasForeignKey(d => d.VolonterId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_DogadjajVolonter_Volonter");
        });

        modelBuilder.Entity<Donacija>(entity =>
        {
            entity.ToTable("Donacija");

            entity.Property(e => e.DatumDonacije).HasDefaultValueSql("(sysdatetime())");
            entity.Property(e => e.Iznos).HasColumnType("decimal(18, 2)");
            entity.Property(e => e.Napomena).HasMaxLength(1000);
            entity.Property(e => e.StripePaymentIntentId).HasMaxLength(200);
            entity.Property(e => e.StripeRefundId).HasMaxLength(200);
            entity.Property(e => e.RazlogOdbijanja).HasMaxLength(1000);
            entity.Property(e => e.RazlogVracanja).HasMaxLength(1000);

            entity.HasOne(d => d.Korisnik).WithMany(p => p.DonacijaKorisniks)
                .HasForeignKey(d => d.KorisnikId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Donacija_Korisnik");

            entity.HasOne(d => d.ObradioKorisnik).WithMany(p => p.DonacijaObradioKorisniks)
                .HasForeignKey(d => d.ObradioKorisnikId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Donacija_ObradioKorisnik");

            entity.HasOne(d => d.StatusDonacije).WithMany(p => p.Donacijas)
                .HasForeignKey(d => d.StatusDonacijeId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Donacija_Status");

            entity.HasOne(d => d.TipDonacije).WithMany(p => p.Donacijas)
                .HasForeignKey(d => d.TipDonacijeId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Donacija_Tip");
        });

        modelBuilder.Entity<Grad>(entity =>
        {
            entity.ToTable("Grad");

            entity.Property(e => e.Naziv).HasMaxLength(100);
            entity.Property(e => e.PostanskiBroj).HasMaxLength(20);
        });

        modelBuilder.Entity<Korisnik>(entity =>
        {
            entity.ToTable("Korisnik");

            entity.HasIndex(e => e.Email, "UQ_Korisnik_Email").IsUnique();

            entity.HasIndex(e => e.KorisnickoIme, "UQ_Korisnik_KorisnickoIme").IsUnique();

            entity.Property(e => e.Adresa).HasMaxLength(255);
            entity.Property(e => e.Aktivan).HasDefaultValue(true, "DF_Korisnik_Aktivan");
            entity.Property(e => e.DatumRegistracije).HasDefaultValueSql("(sysdatetime())", "DF_Korisnik_DatumRegistracije");
            entity.Property(e => e.Email).HasMaxLength(255);
            entity.Property(e => e.Ime).HasMaxLength(100);
            entity.Property(e => e.KorisnickoIme).HasMaxLength(100);
            entity.Property(e => e.LozinkaHash).HasMaxLength(512);
            entity.Property(e => e.LozinkaSalt).HasMaxLength(256);
            entity.Property(e => e.Prezime).HasMaxLength(100);
            entity.Property(e => e.SlikaPutanja).HasMaxLength(500);
            entity.Property(e => e.Telefon).HasMaxLength(30);

            entity.HasOne(d => d.Grad).WithMany(p => p.Korisniks)
                .HasForeignKey(d => d.GradId)
                .HasConstraintName("FK_Korisnik_Grad");
        });

        modelBuilder.Entity<KorisnikUloga>(entity =>
        {
            entity.ToTable("KorisnikUloga");

            entity.HasIndex(e => new { e.KorisnikId, e.UlogaId }, "UQ_KorisnikUloga").IsUnique();

            entity.HasOne(d => d.Korisnik).WithMany(p => p.KorisnikUlogas)
                .HasForeignKey(d => d.KorisnikId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_KorisnikUloga_Korisnik");

            entity.HasOne(d => d.Uloga).WithMany(p => p.KorisnikUlogas)
                .HasForeignKey(d => d.UlogaId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_KorisnikUloga_Uloga");
        });

        modelBuilder.Entity<LozinkaResetToken>(entity =>
        {
            entity.ToTable("LozinkaResetToken");

            entity.HasIndex(e => e.KorisnikId, "IX_LozinkaResetToken_KorisnikId");

            entity.Property(e => e.KodHash).HasMaxLength(128);
            entity.Property(e => e.DatumKreiranja).HasDefaultValueSql("(sysdatetime())");
            entity.Property(e => e.Iskoristen).HasDefaultValue(false);

            entity.HasOne(d => d.Korisnik).WithMany(p => p.LozinkaResetTokens)
                .HasForeignKey(d => d.KorisnikId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_LozinkaResetToken_Korisnik");
        });

        modelBuilder.Entity<Notifikacija>(entity =>
        {
            entity.ToTable("Notifikacija");

            entity.HasIndex(e => new { e.KorisnikId, e.Procitano }, "IX_Notifikacija_Korisnik_Procitano");

            entity.Property(e => e.Tip).HasMaxLength(50);
            entity.Property(e => e.Naslov).HasMaxLength(200);
            entity.Property(e => e.Tekst).HasMaxLength(1000);
            entity.Property(e => e.Procitano).HasDefaultValue(false);
            entity.Property(e => e.DatumKreiranja).HasDefaultValueSql("(sysdatetime())");

            entity.HasOne(d => d.Korisnik).WithMany(p => p.Notifikacijas)
                .HasForeignKey(d => d.KorisnikId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Notifikacija_Korisnik");
        });

        modelBuilder.Entity<Obavijest>(entity =>
        {
            entity.ToTable("Obavijest");

            entity.Property(e => e.Aktivna).HasDefaultValue(true);
            entity.Property(e => e.DatumObjave).HasDefaultValueSql("(sysdatetime())");
            entity.Property(e => e.Naslov).HasMaxLength(200);
            entity.Property(e => e.SlikaPutanja).HasMaxLength(500);

            entity.HasOne(d => d.Autor).WithMany(p => p.Obavijests)
                .HasForeignKey(d => d.AutorId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Obavijest_Autor");
        });

        modelBuilder.Entity<Pas>(entity =>
        {
            entity.HasKey(e => e.PasId);

            entity.Property(e => e.Aktivan).HasDefaultValue(true, "DF_Pas_Aktivan");
            entity.Property(e => e.Naziv).HasMaxLength(100);
            entity.Property(e => e.SlikaNaslovna).HasMaxLength(500);
            entity.Property(e => e.Tezina).HasColumnType("decimal(5, 2)");

            entity.HasOne(d => d.Rasa).WithMany(p => p.Pas)
                .HasForeignKey(d => d.RasaId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Pas_Rasa");

            entity.HasOne(d => d.StatusPsa).WithMany(p => p.Pas)
                .HasForeignKey(d => d.StatusPsaId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Pas_Status");

            entity.HasOne(d => d.VelicinaPsa).WithMany(p => p.Pas)
                .HasForeignKey(d => d.VelicinaPsaId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Pas_Velicina");
        });

        modelBuilder.Entity<Posjeta>(entity =>
        {
            entity.HasKey(e => e.PosjetaId);

            entity.Property(e => e.Napomena).HasMaxLength(1000);
            entity.Property(e => e.RazlogOtkazivanja).HasMaxLength(1000);

            entity.HasOne(d => d.Korisnik).WithMany(p => p.PosjetaKorisniks)
                .HasForeignKey(d => d.KorisnikId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Posjeta_Korisnik");

            entity.HasOne(d => d.ObradioKorisnik).WithMany(p => p.PosjetaObradioKorisniks)
                .HasForeignKey(d => d.ObradioKorisnikId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Posjeta_ObradioKorisnik");

            entity.HasOne(d => d.Pas).WithMany(p => p.Posjetas)
                .HasForeignKey(d => d.PasId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Posjeta_Pas");

            entity.HasOne(d => d.StatusPosjete).WithMany(p => p.Posjeta)
                .HasForeignKey(d => d.StatusPosjeteId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Posjeta_Status");
        });

        modelBuilder.Entity<PregledPsa>(entity =>
        {
            entity.ToTable("PregledPsa");

            entity.Property(e => e.DatumPregleda).HasDefaultValueSql("(sysdatetime())");

            entity.HasOne(d => d.Korisnik).WithMany(p => p.PregledPsas)
                .HasForeignKey(d => d.KorisnikId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_PregledPsa_Korisnik");

            entity.HasOne(d => d.Pas).WithMany(p => p.PregledPsas)
                .HasForeignKey(d => d.PasId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_PregledPsa_Pas");
        });

        modelBuilder.Entity<Rasa>(entity =>
        {
            entity.ToTable("Rasa");

            entity.HasIndex(e => e.Naziv, "UQ_Rasa").IsUnique();

            entity.Property(e => e.Aktivan).HasDefaultValue(true, "DF_Rasa_Aktivan");
            entity.Property(e => e.Naziv).HasMaxLength(100);
        });

        modelBuilder.Entity<SlikaPsa>(entity =>
        {
            entity.ToTable("SlikaPsa");

            entity.Property(e => e.Putanja).HasMaxLength(500);

            entity.HasOne(d => d.Pas).WithMany(p => p.SlikaPsas)
                .HasForeignKey(d => d.PasId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_SlikaPsa_Pas");
        });

        modelBuilder.Entity<StatusDonacije>(entity =>
        {
            entity.ToTable("StatusDonacije");

            entity.HasIndex(e => e.Naziv, "UQ_StatusDonacije").IsUnique();

            entity.Property(e => e.Naziv).HasMaxLength(50);
        });

        modelBuilder.Entity<StatusPosjete>(entity =>
        {
            entity.ToTable("StatusPosjete");

            entity.HasIndex(e => e.Naziv, "UQ_StatusPosjete").IsUnique();

            entity.Property(e => e.Naziv).HasMaxLength(50);
        });

        modelBuilder.Entity<StatusPsa>(entity =>
        {
            entity.ToTable("StatusPsa");

            entity.HasIndex(e => e.Naziv, "UQ_StatusPsa").IsUnique();

            entity.Property(e => e.Naziv).HasMaxLength(50);
        });

        modelBuilder.Entity<StatusZahtjeva>(entity =>
        {
            entity.ToTable("StatusZahtjeva");

            entity.HasIndex(e => e.Naziv, "UQ_StatusZahtjeva").IsUnique();

            entity.Property(e => e.Naziv).HasMaxLength(50);
        });

        modelBuilder.Entity<TipAktivnosti>(entity =>
        {
            entity.ToTable("TipAktivnosti");

            entity.HasIndex(e => e.Naziv, "UQ_TipAktivnosti").IsUnique();

            entity.Property(e => e.Naziv).HasMaxLength(100);
        });

        modelBuilder.Entity<TipDonacije>(entity =>
        {
            entity.ToTable("TipDonacije");

            entity.HasIndex(e => e.Naziv, "UQ_TipDonacije").IsUnique();

            entity.Property(e => e.Naziv).HasMaxLength(50);
        });

        modelBuilder.Entity<Udomljavanje>(entity =>
        {
            entity.ToTable("Udomljavanje");

            entity.HasIndex(e => e.ZahtjevZaUdomljavanjeId, "UQ_Udomljavanje").IsUnique();

            entity.Property(e => e.Napomena).HasMaxLength(1000);

            entity.HasOne(d => d.ZahtjevZaUdomljavanje).WithOne(p => p.Udomljavanje)
                .HasForeignKey<Udomljavanje>(d => d.ZahtjevZaUdomljavanjeId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Udomljavanje_Zahtjev");
        });

        modelBuilder.Entity<Uloga>(entity =>
        {
            entity.ToTable("Uloga");

            entity.HasIndex(e => e.Naziv, "UQ_Uloga_Naziv").IsUnique();

            entity.Property(e => e.Naziv).HasMaxLength(50);
        });

        modelBuilder.Entity<VelicinaPsa>(entity =>
        {
            entity.ToTable("VelicinaPsa");

            entity.HasIndex(e => e.Naziv, "UQ_VelicinaPsa").IsUnique();

            entity.Property(e => e.Naziv).HasMaxLength(50);
        });

        modelBuilder.Entity<Volonter>(entity =>
        {
            entity.ToTable("Volonter");

            entity.HasIndex(e => e.KorisnikId, "UQ_Volonter").IsUnique();

            entity.Property(e => e.Aktivan).HasDefaultValue(true);

            entity.HasOne(d => d.Korisnik).WithOne(p => p.Volonter)
                .HasForeignKey<Volonter>(d => d.KorisnikId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK_Volonter_Korisnik");
        });

        modelBuilder.Entity<ZahtjevZaUdomljavanje>(entity =>
        {
            entity.ToTable("ZahtjevZaUdomljavanje");

            entity.Property(e => e.DatumPodnosenja).HasDefaultValueSql("(sysdatetime())");
            entity.Property(e => e.Napomena).HasMaxLength(1000);
            entity.Property(e => e.RazlogOdbijanja).HasMaxLength(1000);

            entity.HasOne(d => d.Korisnik).WithMany(p => p.ZahtjevZaUdomljavanjeKorisniks)
                .HasForeignKey(d => d.KorisnikId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__ZahtjevZa__Koris__4CA06362");

            entity.HasOne(d => d.ObradioKorisnik).WithMany(p => p.ZahtjevZaUdomljavanjeObradioKorisniks)
                .HasForeignKey(d => d.ObradioKorisnikId)
                .HasConstraintName("FK__ZahtjevZa__Obrad__4F7CD00D");

            entity.HasOne(d => d.Pas).WithMany(p => p.ZahtjevZaUdomljavanjes)
                .HasForeignKey(d => d.PasId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__ZahtjevZa__PasId__4D94879B");

            entity.HasOne(d => d.StatusZahtjeva).WithMany(p => p.ZahtjevZaUdomljavanjes)
                .HasForeignKey(d => d.StatusZahtjevaId)
                .OnDelete(DeleteBehavior.ClientSetNull)
                .HasConstraintName("FK__ZahtjevZa__Statu__4E88ABD4");
        });

        OnModelCreatingPartial(modelBuilder);
    }

    partial void OnModelCreatingPartial(ModelBuilder modelBuilder);
}
