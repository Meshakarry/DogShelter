using DogShelter.Model.Requests;

namespace DogShelter.Services.Interfaces;

public interface IPretragaLogService
{
    /// <summary>
    /// Records a dog search's filters as a recommender signal - a no-op when the search has no
    /// filter set at all (an unfiltered browse says nothing about preference) or when the caller
    /// is an admin (desktop management browsing isn't a user preference signal).
    /// </summary>
    Task LogPretragaAsync(PasSearchRequest search, int korisnikId, bool isAdmin);
}
