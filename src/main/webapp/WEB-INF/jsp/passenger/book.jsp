<% request.setAttribute("fullPage", true); %>
<%@ include file="../common/header.jsp" %>
<div class="bk-steps"><div class="container"><ol>
<li class="on"><span class="n">1</span> Choose your fare</li><li class="on"><span class="n">2</span> Your details</li><li><span class="n">3</span> Extras</li><li><span class="n">4</span> Check and pay</li></ol></div></div>
<div class="container">

<div class="card card-skybook p-4 mb-4">
    <div class="row align-items-center">
        <div class="col-md-3"><strong>${flight.airlineName}</strong><div class="text-muted small">${flight.aircraftModel}</div></div>
        <div class="col-md-6">
            <div class="d-flex align-items-center">
                <div class="text-center"><div class="fw-bold">${flight.departureAirportId}</div><div class="small text-muted">${flight.departureFormatted}</div></div>
                <div class="route-line"></div>
                <div class="text-center"><div class="fw-bold">${flight.arrivalAirportId}</div><div class="small text-muted">${flight.arrivalFormatted}</div></div>
            </div>
        </div>
        <div class="col-md-3 text-end">
            <div class="text-muted small">Base fare + tax</div>
            <div class="fs-5 fw-bold">&#8377;<fmt:formatNumber value="${flight.totalPrice}" maxFractionDigits="0"/></div>
        </div>
    </div>
</div>

<form method="post" action="${pageContext.request.contextPath}/passenger/book" id="bookForm">
    <input type="hidden" name="flightId" value="${flight.flightId}">
    <input type="hidden" name="seatNumber" id="seatNumberInput" value="">

    <div class="row g-4">
        <div class="col-lg-7">

            <div class="card card-skybook p-3 mb-4">
                <h5>1. Choose a seat</h5>
                <div class="d-flex gap-3 small text-muted mb-2">
                    <span><span class="seat-btn seat-window d-inline-block" style="width:16px;height:16px;vertical-align:middle"></span> Window</span>
                    <span><span class="seat-btn seat-aisle d-inline-block" style="width:16px;height:16px;vertical-align:middle"></span> Aisle</span>
                    <span><span class="seat-btn seat-taken d-inline-block" style="width:16px;height:16px;vertical-align:middle"></span> Taken</span>
                    <span><span class="seat-btn selected d-inline-block" style="width:16px;height:16px;vertical-align:middle"></span> Selected</span>
                </div>
                <div class="d-flex flex-wrap gap-2">
                    <c:forEach var="s" items="${seats}">
                        <button type="button"
                                class="seat-btn ${s.seatPosition == 'Window' ? 'seat-window' : (s.seatPosition == 'Aisle' ? 'seat-aisle' : '')} ${s.seatClass == 'Business' ? 'seat-business' : ''} ${!s.available ? 'seat-taken' : ''}"
                                data-seat="${s.seatNumber}"
                                data-surcharge="${s.seatSurcharge}"
                                ${!s.available ? 'disabled' : ''}
                                onclick="selectSeat(this)">${s.seatNumber}</button>
                    </c:forEach>
                </div>
                <div class="mt-2">Selected seat: <strong id="seatLabel">none</strong></div>
            </div>

            <div class="card card-skybook p-3 mb-4">
                <h5>2. Meals (optional)</h5>
                <c:if test="${empty meals}"><p class="text-muted mb-0">No meals offered on this flight.</p></c:if>
                <c:forEach var="m" items="${meals}">
                    <div class="d-flex justify-content-between align-items-center border-bottom py-2">
                        <div>
                            <div>${m.mealName} <span class="text-muted small">(${m.dietType})</span></div>
                            <div class="text-muted small">&#8377;${m.price}</div>
                        </div>
                        <input type="number" class="form-control meal-qty" style="width:80px" name="meal_${m.mealId}"
                               data-price="${m.price}" min="0" max="6" value="0" onchange="recalc()">
                    </div>
                </c:forEach>
            </div>

            <div class="card card-skybook p-3 mb-4">
                <h5>3. Extra luggage</h5>
                <label class="form-label">Extra kg (&#8377;300/kg)</label>
                <input type="number" class="form-control" style="width:140px" name="extraKg" id="extraKg"
                       min="0" step="1" value="0" onchange="recalc()">
            </div>

            <div class="card card-skybook p-3 mb-4">
                <h5>4. Traveler details</h5>
                <div class="row g-3">
                    <div class="col-md-6"><label class="form-label">First Name</label>
                        <input class="form-control" name="firstName" value="${passenger.firstName}" required></div>
                    <div class="col-md-6"><label class="form-label">Last Name</label>
                        <input class="form-control" name="lastName" value="${passenger.lastName}"></div>
                    <div class="col-md-6"><label class="form-label">Email</label>
                        <input class="form-control" type="email" name="email" value="${passenger.email}" required></div>
                    <div class="col-md-6"><label class="form-label">Contact No</label>
                        <input class="form-control" name="contactNo" value="${passenger.contactNo}"></div>
                    <div class="col-md-6"><label class="form-label">Date of Birth</label>
                        <input class="form-control" type="date" name="dob" value="${passenger.dateOfBirth}" required></div>
                    <div class="col-md-6"><label class="form-label">Passport (optional)</label>
                        <input class="form-control" name="passport" value="${passenger.passportNumber}"></div>
                </div>
            </div>

            <div class="card card-skybook p-3 mb-4">
                <h5>5. Payment</h5>
                <select class="form-select" name="paymentMethod" required>
                    <option value="UPI">UPI</option>
                    <option value="Card">Card</option>
                    <option value="NetBanking">Net Banking</option>
                    <option value="Wallet">Wallet</option>
                    <option value="Cash">Cash</option>
                </select>
            </div>
        </div>

        <div class="col-lg-5">
            <div class="card card-skybook p-4" style="position:sticky; top:1rem;">
                <h5>Fare Summary</h5>
                <div class="d-flex justify-content-between"><span>Base + tax</span><span>&#8377;<fmt:formatNumber value="${flight.totalPrice}" maxFractionDigits="0"/></span></div>
                <div class="d-flex justify-content-between"><span>Seat surcharge</span><span id="sumSeat">&#8377;0</span></div>
                <div class="d-flex justify-content-between"><span>Meals</span><span id="sumMeals">&#8377;0</span></div>
                <div class="d-flex justify-content-between"><span>Luggage</span><span id="sumLuggage">&#8377;0</span></div>
                <hr>
                <div class="d-flex justify-content-between fw-bold fs-5"><span>Total (est.)</span><span id="sumTotal">&#8377;<fmt:formatNumber value="${flight.totalPrice}" maxFractionDigits="0"/></span></div>
                <p class="text-muted small mt-2">Final amount is calculated securely on the server at checkout.</p>
                <button class="btn btn-sb-accent w-100 mt-2" type="submit">Confirm &amp; Pay</button>
            </div>
        </div>
    </div>
</form>

<script>
    var baseTotal = ${flight.totalPrice};
    var selectedSurcharge = 0;

    function selectSeat(btn) {
        document.querySelectorAll('.seat-btn').forEach(function(b){ b.classList.remove('selected'); });
        btn.classList.add('selected');
        document.getElementById('seatNumberInput').value = btn.getAttribute('data-seat');
        document.getElementById('seatLabel').textContent = btn.getAttribute('data-seat');
        selectedSurcharge = parseFloat(btn.getAttribute('data-surcharge')) || 0;
        recalc();
    }

    function recalc() {
        var mealsTotal = 0;
        document.querySelectorAll('.meal-qty').forEach(function(i){
            mealsTotal += (parseFloat(i.value) || 0) * (parseFloat(i.getAttribute('data-price')) || 0);
        });
        var luggage = (parseFloat(document.getElementById('extraKg').value) || 0) * 300;
        var total = baseTotal + selectedSurcharge + mealsTotal + luggage;

        document.getElementById('sumSeat').textContent = '\u20B9' + selectedSurcharge.toFixed(0);
        document.getElementById('sumMeals').textContent = '\u20B9' + mealsTotal.toFixed(0);
        document.getElementById('sumLuggage').textContent = '\u20B9' + luggage.toFixed(0);
        document.getElementById('sumTotal').textContent = '\u20B9' + total.toFixed(0);
    }

    document.getElementById('bookForm').addEventListener('submit', function(e){
        if (!document.getElementById('seatNumberInput').value) {
            e.preventDefault();
            alert('Please select a seat first.');
        }
    });
</script>

</div>
<%@ include file="../common/footer.jsp" %>
