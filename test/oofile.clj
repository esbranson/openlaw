;
; java -cp $HOME/Downloads/clojure-1.6.0/clojure-1.6.0-slim.jar:/usr/share/java/tablelayout.jar:/usr/share/java/java_uno.jar:/usr/share/java/juh.jar:/usr/share/java/jurt.jar:/usr/share/java/ridl.jar:/usr/share/java/unoloader.jar:/usr/share/java/unoil.jar -Djava.library.path=/usr/lib/ure/lib clojure.main
;

(ns org.linkedlaw.oofile)

;; process functions

; XXX relies on PATH, existence of /dev/null
(defn spawn-soffice
  "Spawn an soffice process and return the Process object."
  []
  (let [pb (java.lang.ProcessBuilder. 
             ["soffice" 
              "--accept=pipe,name=officepipe;urp;StarOffice.ServiceManager" 
              "--norestore" 
              "--nologo" 
              "--headless" 
              "--nolockcheck"])]
    (.redirectErrorStream pb true)
    (.redirectOutput pb
      (java.lang.ProcessBuilder$Redirect/appendTo
        (java.io.File. "/dev/null")))
    (.start pb)))

(defn get-uno-desktop
  "Connect to a running soffice process and return a Desktop frame."
  []
  (let [xLocalContext (com.sun.star.comp.helper.Bootstrap/createInitialComponentContext nil)
        xLocalServiceManager (.getServiceManager xLocalContext)
        oUrlResolver (.createInstanceWithContext xLocalServiceManager "com.sun.star.bridge.UnoUrlResolver" xLocalContext)
        xUrlResolver (com.sun.star.uno.UnoRuntime/queryInterface com.sun.star.bridge.XUnoUrlResolver oUrlResolver)]
    (if-let [oContext (first (filter some?
          (for [i (range 3)]
            (try
              (.resolve xUrlResolver "uno:pipe,name=officepipe;urp;StarOffice.ComponentContext")
              (catch java.lang.Exception e (java.lang.Thread/sleep 5000))))))]
      (let [xContext (com.sun.star.uno.UnoRuntime/queryInterface com.sun.star.uno.XComponentContext oContext)
            oMCF (.getServiceManager xContext)
            xMCF (com.sun.star.uno.UnoRuntime/queryInterface com.sun.star.lang.XMultiComponentFactory oMCF)]
        (.createInstanceWithContext xMCF "com.sun.star.frame.Desktop" xContext)))))

(defn terminate-uno-desktop
  "Terminate the Desktop."
  [oDesktop]
  (let [xDesktop (com.sun.star.uno.UnoRuntime/queryInterface com.sun.star.frame.XDesktop oDesktop)]
    (.terminate xDesktop)))

(defn get-uno-doc
  "Given a Desktop frame and filename, open a file and return a XTextDocument object."
  [oDesktop file]
  (let [xCLoader (com.sun.star.uno.UnoRuntime/queryInterface com.sun.star.frame.XComponentLoader oDesktop)
        oDocument (.loadComponentFromURL xCLoader file "_blank" 0 (into-array com.sun.star.beans.PropertyValue []))]
    (com.sun.star.uno.UnoRuntime/queryInterface com.sun.star.text.XTextDocument oDocument)))

;; helper functions

(defn uno-enumeration-seq
  "Wrap a XEnumeration object as a seq."
  [^com.sun.star.container.XEnumeration xEnum]
  (enumeration-seq
    (reify java.util.Enumeration
      (^boolean hasMoreElements [this] (.hasMoreElements xEnum))
      (nextElement [this] (.nextElement xEnum)))))

(defn supports-service?
  "Given a service name, determine if a XComponent object supports the such service."
  [service xComponent]
  (let [xServiceInfo (com.sun.star.uno.UnoRuntime/queryInterface com.sun.star.lang.XServiceInfo xComponent)]
    (.supportsService xServiceInfo service)))

(defn get-property
  "Given a property name and a XComponent object supporting the XPropertySet service, return that property."
  [prop xComp]
  (let [xPropertySet (com.sun.star.uno.UnoRuntime/queryInterface com.sun.star.beans.XPropertySet xComp)]
    (.getPropertyValue xPropertySet prop)))

(defn is-text-portion?
  "Given a XComponent object supporting the TextPortion service, determine if its TextPortionType is Text."
  [xTextPortion]
;  (if (supports-service? "com.sun.star.text.TextPortion" xTextPortion) ; XXX only blank lines are meeting both tests
  (let [xTextPortionType (get-property "TextPortionType" xTextPortion)]
    (= xTextPortionType "Text")))

;; text functions

(defstruct signal-struct :line :adjust :margin :weight)

(defn make-portion-map
  "Given a signal struct and a XComponent object collection with each supporting the TextPortion and CharacterProperties services, 
  return a signal struct with a concatenated string and the last object's CharWeight property."
  [signal coll]
  (loop [sb (java.lang.StringBuilder.)
         weight nil
         more coll]
    (if more
      (let [xComp (first more)]
        (recur (.append sb (.getString xComp))
               (get-property "CharWeight" xComp)
               (next more)))
      (assoc signal :line (str sb) :weight weight))))

(defn get-content-map
  "Given a XTextContent object, return a string that is a concatenation of the sequence of XTextPortion objects that have 'Text' TextPortionType values."
  [signal]
  (let [xTextElement (:xtext signal)
        sig (dissoc signal :xtext)]
    (make-portion-map sig
      (filter is-text-portion?
        (map #(com.sun.star.uno.UnoRuntime/queryInterface com.sun.star.text.XTextRange %)
          (uno-enumeration-seq
            (.createEnumeration
              (com.sun.star.uno.UnoRuntime/queryInterface com.sun.star.container.XEnumerationAccess xTextElement))))))))

; XXX doesnt do properties at the moment
(defn make-content-map
  "Given a XTextContent object, return a signal struct with the XTextContent object and their associated properties ParaLeftMargin and ParaAdjust."
  [xTextElement]
  (let [signal (struct signal-struct nil nil nil nil)]
    (assoc signal :xtext xTextElement))) ; NOTE rm or memory leak!

(defn get-doc-content
  "Given a XTextDocument object, return a sequence of signal structs containing XTextContent objects that support the Paragraph service,
   as well as their associated ParaLeftMargin and ParaAdjust."
  [xDoc]
  (map make-content-map
    (filter #(supports-service? "com.sun.star.text.Paragraph" %)
;    (map #(com.sun.star.uno.UnoRuntime/queryInterface com.sun.star.text.XTextContent %) ; not needed for some reason
      (uno-enumeration-seq
        (.createEnumeration
          (com.sun.star.uno.UnoRuntime/queryInterface com.sun.star.container.XEnumerationAccess (.getText xDoc)))))))

(defn get-doc-maps
  "Given a XTextDocument object, return a sequence of maps representing paragraphs and their properties."
  [xDoc]
  (map get-content-map (get-doc-content xDoc)))

;; test functions

(defn t-get-uno-doc
  ""
  []
  (let [p (spawn-soffice)
        desktop (get-uno-desktop)
        doc-one (get-uno-doc desktop "file:///home/msr/src/openlaw-test/us-co-law/crs2013/CRS%20Title%2024%20(2013).rtf")]
    (if (some? doc-one)
      (do
        (doseq [m (get-doc-maps doc-one)]
          (prn m))
        (.dispose doc-one)
        (terminate-uno-desktop desktop)
        (println "Terminated soffice.")
        (.waitFor p))
      (println "No document."))))

