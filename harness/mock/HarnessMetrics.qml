import QtQuick

Item {
    id: root
    visible: false

    required property var greeter
    property bool metricsEnabled: false
    property var intervals: []
    property double previousTick: 0

    Connections {
        target: root.greeter
        enabled: root.metricsEnabled
        function onShaderTimeChanged() {
            const now = Date.now();
            if (root.previousTick > 0 && root.intervals.length < 500)
                root.intervals.push(now - root.previousTick);
            root.previousTick = now;
        }
    }

    Timer {
        interval: 6000
        running: root.metricsEnabled
        repeat: false
        onTriggered: {
            const samples = root.intervals.slice().sort((a, b) => a - b);
            if (samples.length < 10) {
                console.info("HARNESS_CADENCE insufficient samples");
                return;
            }
            const percentile = p => samples[Math.min(samples.length - 1, Math.floor(samples.length * p))];
            console.info("HARNESS_CADENCE samples=" + samples.length
                         + " median_ms=" + percentile(.5)
                         + " p95_ms=" + percentile(.95)
                         + " p99_ms=" + percentile(.99));
        }
    }
}
