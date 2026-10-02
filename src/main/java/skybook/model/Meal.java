package skybook.model;

import java.math.BigDecimal;

/**
 * Meal — maps to the Meals table.
 * MealCategory: Snack (flight < 2 hrs) | Meal (flight >= 2 hrs)
 * DietType:     Veg | Non-Veg
 * MealType:     Vegetarian | Non-Vegetarian | Vegan | Jain | Special
 *
 * Java-II U1: Interface implemented in service (Priceable).
 * Java-II U6: Meals stored in HashMap<Integer,Meal> in MealDAO cache.
 */
public class Meal {

    public enum MealCategory { Snack, Meal }
    public enum DietType     { Veg, NonVeg }
    public enum MealType     { Vegetarian, NonVegetarian, Vegan, Jain, Special }

    private int          mealId;
    private int          airlineId;
    private String       mealName;
    private MealCategory mealCategory;
    private DietType     dietType;
    private MealType     mealType;
    private BigDecimal   price;

    // Joined field
    private String airlineName;

    public Meal() {}

    public Meal(int airlineId, String mealName, MealCategory mealCategory,
                DietType dietType, MealType mealType, BigDecimal price) {
        this.airlineId    = airlineId;
        this.mealName     = mealName;
        this.mealCategory = mealCategory;
        this.dietType     = dietType;
        this.mealType     = mealType;
        this.price        = price;
    }

    // Getters & Setters
    public int getMealId()                        { return mealId; }
    public void setMealId(int id)                 { this.mealId = id; }
    public int getAirlineId()                     { return airlineId; }
    public void setAirlineId(int id)              { this.airlineId = id; }
    public String getMealName()                   { return mealName; }
    public void setMealName(String n)             { this.mealName = n; }
    public MealCategory getMealCategory()         { return mealCategory; }
    public void setMealCategory(MealCategory c)   { this.mealCategory = c; }
    public DietType getDietType()                 { return dietType; }
    public void setDietType(DietType d)           { this.dietType = d; }
    public MealType getMealType()                 { return mealType; }
    public void setMealType(MealType t)           { this.mealType = t; }
    public BigDecimal getPrice()                  { return price; }
    public void setPrice(BigDecimal p)            { this.price = p; }
    public String getAirlineName()                { return airlineName; }
    public void setAirlineName(String n)          { this.airlineName = n; }

    @Override
    public String toString() {
        return String.format("Meal[%d] %-25s %-7s %-7s %-14s ₹%.0f",
                mealId, mealName, mealCategory, dietType, mealType, price);
    }
}
