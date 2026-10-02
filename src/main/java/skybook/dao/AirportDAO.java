package skybook.dao;

import skybook.exception.Exceptions.DatabaseException;
import skybook.model.Airport;
import skybook.util.DBConnection;

import java.sql.Connection;
import java.sql.PreparedStatement;
import java.sql.ResultSet;
import java.sql.SQLException;
import java.sql.Statement;
import java.util.ArrayList;
import java.util.List;

/**
 * AirportDAO — read access to the Airports table.
 *
 * WEB CONVERSION NOTE: the console app looked up airports through an in-memory
 * Trie (skybook.ds.AirportTrie) built once at startup, driven by typed input.
 * The website instead renders a simple HTML select/dropdown of every airport,
 * so a plain list query is all that's needed here.
 */
public class AirportDAO {

    public List<Airport> findAll() throws DatabaseException {
        String sql = "SELECT AirportCode, AirportName, City, Country, TimeZone " +
                     "FROM Airports ORDER BY City, AirportCode";
        List<Airport> list = new ArrayList<>();
        try (Connection c = DBConnection.getConnection();
             Statement s = c.createStatement();
             ResultSet rs = s.executeQuery(sql)) {
            while (rs.next()) {
                Airport a = new Airport();
                a.setAirportCode(rs.getString("AirportCode"));
                a.setAirportName(rs.getString("AirportName"));
                a.setCity(rs.getString("City"));
                a.setCountry(rs.getString("Country"));
                a.setTimeZone(rs.getString("TimeZone"));
                list.add(a);
            }
            return list;
        } catch (SQLException e) {
            throw new DatabaseException("AirportDAO.findAll", e);
        }
    }

    public Airport findByCode(String code) throws DatabaseException {
        String sql = "SELECT AirportCode, AirportName, City, Country, TimeZone " +
                     "FROM Airports WHERE AirportCode = ?";
        try (Connection c = DBConnection.getConnection();
             PreparedStatement ps = c.prepareStatement(sql)) {
            ps.setString(1, code);
            try (ResultSet rs = ps.executeQuery()) {
                if (rs.next()) {
                    Airport a = new Airport();
                    a.setAirportCode(rs.getString("AirportCode"));
                    a.setAirportName(rs.getString("AirportName"));
                    a.setCity(rs.getString("City"));
                    a.setCountry(rs.getString("Country"));
                    a.setTimeZone(rs.getString("TimeZone"));
                    return a;
                }
            }
            return null;
        } catch (SQLException e) {
            throw new DatabaseException("AirportDAO.findByCode", e);
        }
    }
}
