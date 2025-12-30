#!/usr/bin/env python3
"""
Astral Calculator Script for SprigRig

This script calculates sunrise, sunset, and other astronomical events
based on location and date.
"""

import argparse
import json
import logging
import sys
import datetime
from zoneinfo import ZoneInfo
import astral
from astral.sun import sun

# Configure logging
logging.basicConfig(
    level=logging.INFO,
    format='%(asctime)s - %(name)s - %(levelname)s - %(message)s',
    handlers=[
        logging.FileHandler("/var/log/sprigrig/hardware.log"),
        logging.StreamHandler(sys.stdout)
    ]
)
logger = logging.getLogger("astral_calculator")

def calculate_sun_events(latitude, longitude, date, timezone):
    """Calculate sun events for a specific location and date"""
    try:
        # Create a location object
        location = astral.LocationInfo(
            name='Custom',
            region='Region',
            timezone=timezone,
            latitude=latitude,
            longitude=longitude
        )
        
        # Parse the date
        if isinstance(date, str):
            date_parts = date.split('-')
            if len(date_parts) == 3:
                year, month, day = map(int, date_parts)
                date = datetime.date(year, month, day)
            else:
                date = datetime.date.today()
        elif not isinstance(date, datetime.date):
            date = datetime.date.today()
        
        # Create timezone object
        tz = ZoneInfo(timezone)
        
        # Calculate sun events
        s = sun(location.observer, date=date, tzinfo=tz)
        
        # Format the results
        results = {
            'dawn': s['dawn'].strftime('%Y-%m-%d %H:%M:%S'),
            'sunrise': s['sunrise'].strftime('%Y-%m-%d %H:%M:%S'),
            'noon': s['noon'].strftime('%Y-%m-%d %H:%M:%S'),
            'sunset': s['sunset'].strftime('%Y-%m-%d %H:%M:%S'),
            'dusk': s['dusk'].strftime('%Y-%m-%d %H:%M:%S'),
            'day_length': (s['sunset'] - s['sunrise']).total_seconds() / 3600.0,  # in hours
            'night_length': 24.0 - ((s['sunset'] - s['sunrise']).total_seconds() / 3600.0),
            'date': date.strftime('%Y-%m-%d'),
            'timezone': timezone
        }
        
        logger.info(f"Calculated sun events for {date.strftime('%Y-%m-%d')} at {latitude}, {longitude}")
        return results
    except Exception as e:
        logger.error(f"Error calculating sun events: {e}")
        return None

def calculate_specific_event(latitude, longitude, date, timezone, event):
    """Calculate a specific sun event"""
    try:
        # Calculate all events
        events = calculate_sun_events(latitude, longitude, date, timezone)
        if not events:
            return None
        
        # Return the specific event
        if event in events:
            return events[event]
        else:
            logger.error(f"Unknown event: {event}")
            return None
    except Exception as e:
        logger.error(f"Error calculating {event}: {e}")
        return None

def calculate_events_for_month(latitude, longitude, year, month, timezone):
    """Calculate sun events for every day in a month"""
    try:
        # Determine number of days in the month
        if month == 12:
            next_month = datetime.date(year + 1, 1, 1)
        else:
            next_month = datetime.date(year, month + 1, 1)
        
        last_day = (next_month - datetime.timedelta(days=1)).day
        
        # Calculate events for each day
        results = {}
        for day in range(1, last_day + 1):
            date = datetime.date(year, month, day)
            events = calculate_sun_events(latitude, longitude, date, timezone)
            if events:
                results[date.strftime('%Y-%m-%d')] = events
        
        logger.info(f"Calculated sun events for {year}-{month:02d} at {latitude}, {longitude}")
        return results
    except Exception as e:
        logger.error(f"Error calculating events for month: {e}")
        return None

def is_daytime(latitude, longitude, timezone):
    """Check if it's currently daytime at the specified location"""
    try:
        # Get current date and time
        now = datetime.datetime.now(ZoneInfo(timezone))
        today = now.date()
        
        # Calculate sun events for today
        events = calculate_sun_events(latitude, longitude, today, timezone)
        if not events:
            return None
        
        # Parse sunrise and sunset times
        sunrise = datetime.datetime.strptime(events['sunrise'], '%Y-%m-%d %H:%M:%S')
        sunrise = sunrise.replace(tzinfo=ZoneInfo(timezone))
        
        sunset = datetime.datetime.strptime(events['sunset'], '%Y-%m-%d %H:%M:%S')
        sunset = sunset.replace(tzinfo=ZoneInfo(timezone))
        
        # Check if current time is between sunrise and sunset
        is_day = (now >= sunrise and now <= sunset)
        
        result = {
            'is_daytime': is_day,
            'current_time': now.strftime('%Y-%m-%d %H:%M:%S'),
            'sunrise': events['sunrise'],
            'sunset': events['sunset'],
            'time_since_sunrise': (now - sunrise).total_seconds() / 3600.0 if is_day else None,
            'time_until_sunset': (sunset - now).total_seconds() / 3600.0 if is_day else None,
        }
        
        logger.info(f"Daytime check: {is_day}")
        return result
    except Exception as e:
        logger.error(f"Error checking daytime: {e}")
        return None

def get_next_event(latitude, longitude, timezone):
    """Get the next sun event from the current time"""
    try:
        # Get current date and time
        now = datetime.datetime.now(ZoneInfo(timezone))
        today = now.date()
        
        # Calculate sun events for today
        events = calculate_sun_events(latitude, longitude, today, timezone)
        if not events:
            return None
        
        # Parse event times
        event_times = {}
        for event_name in ['dawn', 'sunrise', 'noon', 'sunset', 'dusk']:
            event_time = datetime.datetime.strptime(events[event_name], '%Y-%m-%d %H:%M:%S')
            event_time = event_time.replace(tzinfo=ZoneInfo(timezone))
            event_times[event_name] = event_time
        
        # Find the next event
        next_event = None
        next_event_name = None
        
        for event_name, event_time in event_times.items():
            if event_time > now:
                if next_event is None or event_time < next_event:
                    next_event = event_time
                    next_event_name = event_name
        
        # If no event found today, get tomorrow's dawn
        if next_event is None:
            tomorrow = today + datetime.timedelta(days=1)
            tomorrow_events = calculate_sun_events(latitude, longitude, tomorrow, timezone)
            
            if tomorrow_events:
                dawn_time = datetime.datetime.strptime(tomorrow_events['dawn'], '%Y-%m-%d %H:%M:%S')
                dawn_time = dawn_time.replace(tzinfo=ZoneInfo(timezone))
                next_event = dawn_time
                next_event_name = 'dawn'
        
        if next_event is not None:
            result = {
                'event': next_event_name,
                'time': next_event.strftime('%Y-%m-%d %H:%M:%S'),
                'minutes_until': (next_event - now).total_seconds() / 60.0,
                'hours_until': (next_event - now).total_seconds() / 3600.0,
            }
            
            logger.info(f"Next event: {next_event_name} at {next_event.strftime('%H:%M:%S')}")
            return result
        else:
            logger.error("Failed to determine next event")
            return None
    except Exception as e:
        logger.error(f"Error getting next event: {e}")
        return None

def main():
    parser = argparse.ArgumentParser(description="Calculate sunrise, sunset, and other astronomical events")
    parser.add_argument("--lat", type=float, required=True, help="Latitude")
    parser.add_argument("--lng", type=float, required=True, help="Longitude")
    parser.add_argument("--date", default=datetime.date.today().strftime('%Y-%m-%d'), help="Date in YYYY-MM-DD format")
    parser.add_argument("--tz", required=True, help="Timezone name (e.g., America/New_York)")
    parser.add_argument("--event", choices=['dawn', 'sunrise', 'noon', 'sunset', 'dusk', 'day_length', 'all'], help="Specific event to calculate")
    parser.add_argument("--month", action="store_true", help="Calculate events for the entire month")
    parser.add_argument("--check-daytime", action="store_true", help="Check if it's currently daytime")
    parser.add_argument("--next-event", action="store_true", help="Get the next sun event")
    parser.add_argument("--json", action="store_true", help="Output in JSON format")
    
    args = parser.parse_args()
    
    # Check if it's daytime
    if args.check_daytime:
        result = is_daytime(args.lat, args.lng, args.tz)
        if result:
            if args.json:
                print(json.dumps(result, indent=2))
            else:
                print(f"It is currently {'daytime' if result['is_daytime'] else 'nighttime'}")
                print(f"Current time: {result['current_time']}")
                print(f"Sunrise: {result['sunrise']}")
                print(f"Sunset: {result['sunset']}")
            sys.exit(0)
        else:
            sys.exit(1)
    
    # Get next event
    if args.next_event:
        result = get_next_event(args.lat, args.lng, args.tz)
        if result:
            if args.json:
                print(json.dumps(result, indent=2))
            else:
                print(f"Next event: {result['event']} at {result['time']}")
                print(f"Time until event: {result['minutes_until']:.1f} minutes ({result['hours_until']:.2f} hours)")
            sys.exit(0)
        else:
            sys.exit(1)
    
    # Calculate events for the entire month
    if args.month:
        date_parts = args.date.split('-')
        if len(date_parts) >= 2:
            year = int(date_parts[0])
            month = int(date_parts[1])
            
            results = calculate_events_for_month(args.lat, args.lng, year, month, args.tz)
            if results:
                if args.json:
                    print(json.dumps(results, indent=2))
                else:
                    for date, events in results.items():
                        print(f"Date: {date}")
                        print(f"  Sunrise: {events['sunrise']}")
                        print(f"  Sunset: {events['sunset']}")
                        print(f"  Day length: {events['day_length']:.2f} hours")
                sys.exit(0)
            else:
                sys.exit(1)
    
    # Calculate a specific event or all events
    if args.event:
        if args.event == 'all':
            result = calculate_sun_events(args.lat, args.lng, args.date, args.tz)
            if result:
                if args.json:
                    print(json.dumps(result, indent=2))
                else:
                    for event, time in result.items():
                        print(f"{event}: {time}")
                sys.exit(0)
            else:
                sys.exit(1)
        else:
            result = calculate_specific_event(args.lat, args.lng, args.date, args.tz, args.event)
            if result:
                print(result)
                sys.exit(0)
            else:
                sys.exit(1)
    
    # Default: calculate all events
    result = calculate_sun_events(args.lat, args.lng, args.date, args.tz)
    if result:
        if args.json:
            print(json.dumps(result, indent=2))
        else:
            for event, time in result.items():
                print(f"{event}: {time}")
        sys.exit(0)
    else:
        sys.exit(1)

if __name__ == "__main__":
    main()