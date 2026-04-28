using FluentAssertions;
using Sheetstorm.Domain.Identity;
using Sheetstorm.Domain.Music;

namespace Sheetstorm.Domain.Tests;

/// <summary>
/// Diese Tests rufen <see cref="Sheetstorm.Web.Application.AudiverisOmrEngine.ParseMusicXml"/>
/// indirekt nach, indem sie die Logik nachbauen — wir vermeiden hier einen
/// Project-Reference auf Sheetstorm.Web (das wäre ein Layering-Bruch).
/// Der Parser-Code wäre besser in Domain oder einem eigenen
/// Sheetstorm.Application gehoben — TODO Refactoring.
/// </summary>
public class MusicXmlSmokeTests
{
    private const string MinimalScore = """
        <?xml version="1.0" encoding="UTF-8"?>
        <score-partwise version="3.1">
          <work><work-title>Marsch der Bayerischen Volkspartei</work-title></work>
          <identification>
            <creator type="composer">Anonym</creator>
          </identification>
          <part-list>
            <score-part id="P1"><part-name>Klarinette in B</part-name></score-part>
            <score-part id="P2"><part-name>Trompete 1 in B</part-name></score-part>
            <score-part id="P3"><part-name>Schlagzeug</part-name></score-part>
          </part-list>
        </score-partwise>
        """;

    [Fact]
    public void XDocument_ParsesScorePartwise()
    {
        var doc = System.Xml.Linq.XDocument.Parse(MinimalScore);
        var ns = doc.Root!.GetDefaultNamespace();
        var parts = doc.Descendants(ns + "score-part").ToList();
        parts.Should().HaveCount(3);
        var title = doc.Descendants(ns + "work-title").FirstOrDefault()?.Value;
        title.Should().Be("Marsch der Bayerischen Volkspartei");
        var composer = doc.Descendants(ns + "creator")
            .FirstOrDefault(e => (string?)e.Attribute("type") == "composer")?.Value;
        composer.Should().Be("Anonym");
    }
}
